use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);

our (%modules, %attr, %defs);
our $now = 1_700_000_000;

sub Log3 { return }
sub TimeNow { return scalar gmtime($now) }
sub IsDisabled { return 0 }
sub IsValidHex { return defined($_[0]) && $_[0] =~ /\A[0-9A-Fa-f]{$_[1]}\z/ }
sub ReadingsVal {
    my ($name, $reading, $default) = @_;
    return $defs{$name}{READINGS}{$reading}{VAL} // $default;
}
sub ReadingsNum {
    my ($name, $reading, $default) = @_;
    my $value = ReadingsVal($name, $reading, $default);
    return looks_like_number($value) ? 0 + $value : $default;
}
sub AttrNum {
    my ($name, $key, $default) = @_;
    return exists $attr{$name}{$key} ? 0 + $attr{$name}{$key} : $default;
}
sub readingsBeginUpdate { return }
sub readingsEndUpdate { return }
sub readingsSingleUpdate { return readingsBulkUpdate(@_) }
sub readingsBulkUpdate {
    my ($hash, $reading, $value) = @_;
    $hash->{READINGS}{$reading}{VAL} = $value;
    return;
}
sub CommandDeleteReading {
    my (undef, $argument) = @_;
    my ($name, $reading) = split /\s+/, $argument, 2;
    delete $defs{$name}{READINGS}{$reading};
    return;
}

my $module = $ENV{OW_MODULE_PATH} // 'FHEM/00_OW2S0SMSGUARD.pm';
open my $fh, '<', $module or die "open $module: $!";
local $/;
my $source = <$fh>;
close $fh;

my ($decision) = $source =~ /(sub plausibilityDecision\s*\{.*?)(?=\n#####################################)/s;
my ($parse) = $source =~ /(sub ParseFn\s*\{.*?)(?=\n#####################################\n\nsub UpdateReadings)/s;
my ($set) = $source =~ /(sub SetFn\s*\{.*?)(?=\n#####################################\n\nsub GetFn)/s;
die 'ParseFn not found' if !defined $parse;
die 'SetFn not found' if !defined $set;
eval(($decision // '') . $parse . $set);
die $@ if $@;

my $rom = '28FFFD5BB11705E4';

sub fresh_device {
    my (%opts) = @_;
    %modules = (OW2S0SMSGUARD => {defptr => {}});
    %attr = (sensor => {});
    my $sensor = {NAME => 'sensor', addr => $rom, READINGS => {}};
    $defs{sensor} = $sensor;
    $modules{OW2S0SMSGUARD}{defptr}{$rom} = $sensor;
    $attr{sensor}{plausibilityCheck} = $opts{enabled} if exists $opts{enabled};
    $sensor->{READINGS}{temperature}{VAL} = $opts{accepted} if exists $opts{accepted};
    $sensor->{READINGS}{plausibilityAnomalyCount}{VAL} = $opts{anomalies} if exists $opts{anomalies};
    return $sensor;
}

sub feed {
    my ($value) = @_;
    return ParseFn({NAME => 'master'}, "OW,$rom,DS18B20,$value,0,0");
}

sub reading { return $defs{sensor}{READINGS}{$_[0]}{VAL} }

{
    my $sensor = fresh_device(enabled => 0);
    feed(20.0);
    is(reading('temperature'), 20.0, 'disabled mode keeps legacy temperature behavior');
    is(reading('state'), 'T: 20 °C', 'disabled mode keeps legacy state behavior');
}

{
    my $sensor = fresh_device(enabled => 1);
    feed(20.0);
    is(reading('temperatureRaw'), 20.0, 'enabled mode publishes raw temperature');
    is(reading('temperature'), 20.0, 'first in-range value is accepted');
    is(reading('plausibilityStatus'), 'ok', 'first value status is ok');

    feed(85.0);
    is(reading('temperature'), 20.0, 'first large jump holds last accepted value');
    is(reading('plausibilityStatus'), 'confirming', 'first large jump starts confirmation');
    is(reading('plausibilityPendingCount'), 1, 'first jump has pending count one');

    feed(85.1);
    is(reading('temperature'), 20.0, 'second matching jump still holds accepted value');
    is(reading('plausibilityPendingCount'), 2, 'second matching jump increments pending count');

    feed(84.9);
    is(reading('temperature'), 84.9, 'third matching jump is accepted');
    is(reading('plausibilityStatus'), 'ok', 'confirmed jump returns status to ok');
    is(reading('plausibilityPendingCount'), 0, 'confirmed jump clears pending count');
}

{
    fresh_device(enabled => 1);
    feed(20.0);
    feed(85.0);
    feed(50.0);
    feed(-10.0);
    is(reading('temperature'), 20.0, 'three inconsistent jumps are not accepted');
    is(reading('plausibilityPendingCount'), 1, 'inconsistent jump sequence restarts at one');
    feed(20.2);
    is(reading('temperature'), 20.2, 'return near accepted value is accepted immediately');
    is(reading('plausibilityPendingCount'), 0, 'return to normal clears pending state');
}

{
    fresh_device(enabled => 1);
    feed(20.0);
    feed(-127.0) for 1 .. 4;
    is(reading('temperature'), 20.0, 'absolute out-of-range value is never accepted');
    is(reading('plausibilityStatus'), 'fault', 'absolute out-of-range value reports fault');
    is(reading('plausibilityRejectedCount'), 4, 'all out-of-range samples are counted');
    is(reading('plausibilityLastRejected'), -127.0, 'last rejected raw value is visible');
}

{
    fresh_device(enabled => 1, accepted => 20.0);
    feed(85.0);
    is(reading('temperature'), 20.0, 'restart uses persisted accepted temperature');
    is(reading('plausibilityPendingCount'), 1, 'restart starts candidate confirmation normally');
}

{
    fresh_device(enabled => 1);
    feed(20.0);
    feed(85.0);
    feed(20.1);
    is(reading('plausibilityAnomalyCount'), 1, 'isolated jump counts as one anomaly episode');
    ok(defined(reading('plausibilityLastAnomaly')), 'last anomaly timestamp is visible');

    feed(86.0);
    feed(20.2);
    is(reading('plausibilityAnomalyCount'), 2, 'second isolated jump increments lifetime counter');
}

{
    fresh_device(enabled => 1);
    feed(20.0);
    feed(85.0);
    feed(85.1);
    feed(84.9);
    is(reading('plausibilityAnomalyCount'), 0, 'confirmed real step does not count as anomaly');
}

{
    fresh_device(enabled => 1);
    feed(20.0);
    feed(-127.0) for 1 .. 5;
    is(reading('plausibilityAnomalyCount'), 1, 'continuous absolute fault counts as one episode');
    feed(20.1);
    feed(-127.0);
    is(reading('plausibilityAnomalyCount'), 2, 'absolute fault after recovery starts a new episode');
}

{
    fresh_device(enabled => 1, accepted => 20.0, anomalies => 7);
    feed(85.0);
    feed(20.1);
    is(reading('plausibilityAnomalyCount'), 8, 'anomaly counter survives helper-state restart');
}

{
    my $sensor = fresh_device(enabled => 1);
    feed(20.0);
    feed(-127.0);
    my $temperature_before = reading('temperature');
    SetFn($sensor, 'sensor', 'resetPlausibility');
    is(reading('plausibilityAnomalyCount'), 0, 'reset command clears lifetime anomaly counter');
    is(reading('plausibilityRejectedCount'), 0, 'reset command clears rejected sample counter');
    is(reading('plausibilityPendingCount'), 0, 'reset command clears pending candidate counter');
    ok(!defined(reading('plausibilityLastAnomaly')), 'reset command removes last anomaly timestamp');
    is(reading('temperature'), $temperature_before, 'reset command leaves accepted temperature untouched');
}

done_testing;
