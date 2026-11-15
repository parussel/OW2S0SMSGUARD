use strict;
use warnings;
use utf8;
use Test::More;

my $path = $ENV{OW_MODULE_PATH} // 'FHEM/00_OW2S0SMSGUARD.pm';
open my $fh, '<:encoding(UTF-8)', $path or die "cannot read $path: $!";
local $/;
my $source = <$fh>;
close $fh;

like($source, qr{board,26\.0\.html}, 'historic forum link is retained');
like($source, qr{https://forum\.fhem\.de/index\.php\?topic=28447\.0}, 'current module thread is documented');
like($source, qr{Frank Parussel / 153er-netz\.de.*2026-11-15}s, 'full local modification author and date are documented');
for my $attribute (qw(plausibilityCheck plausibilityMin plausibilityMax plausibilityMaxDelta plausibilityConfirmations plausibilityConfirmTolerance)) {
    like($source, qr{\b\Q$attribute\E\b}, "attribute $attribute is documented");
}
for my $reading (qw(temperatureRaw plausibilityStatus plausibilityPendingCount plausibilityRejectedCount plausibilityLastRejected plausibilityAnomalyCount plausibilityLastAnomaly)) {
    like($source, qr{\b\Q$reading\E\b}, "reading $reading is documented");
}
like($source, qr{resetPlausibility}, 'reset command is documented');
like($source, qr{Lokale Erweiterung durch Frank Parussel / 153er-netz\.de}, 'German help contains full local extension notice');
like($source, qr{16\.11\.2026.*00:27.*Client-Cache}s, 'latest reload correction is documented with date and time');
like($source, qr{timestamp-on-change-reading.*PID20}s, 'AutoCreate timestamp note cross-references PID20');
like($source, qr{https://github\.com/parussel/PID20}, 'PID20 project link is documented');

done_testing();
