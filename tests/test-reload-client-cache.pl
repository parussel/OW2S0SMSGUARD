use strict;
use warnings;
use Test::More;

BEGIN {
    package DevIo;
    sub import { return }
    $INC{'DevIo.pm'} = __FILE__;

    package GPUtils;
    sub import {
        my $caller = caller;
        no strict 'refs';
        *{"${caller}::GP_Import"} = \&GP_Import;
        *{"${caller}::GP_Export"} = \&GP_Export;
    }
    sub GP_Import {
        my $caller = caller;
        no strict 'refs';
        for my $name (@_) {
            *{"${caller}::$name"} = *{"main::$name"};
        }
    }
    sub GP_Export { return }
    $INC{'GPUtils.pm'} = __FILE__;
}

our (%attr, %defs, %modules, $init_done, $readingFnAttributes);
$attr{global}{modpath} = '/path/without/meta';
$readingFnAttributes = '';

my $module_path = $ENV{OW_MODULE_PATH} // die 'OW_MODULE_PATH is required';
my $result = do $module_path;
die $@ if $@;
die "could not load $module_path: $!" if !defined $result;

$defs{master_one} = {
    NAME           => 'master_one',
    TYPE           => 'OW2S0SMSGUARD',
    addr           => 'master',
    '.clientArray' => ['OW2S0SMSGUARD'],
};
$defs{master_two} = {
    NAME           => 'master_two',
    TYPE           => 'OW2S0SMSGUARD',
    addr           => 'master',
    '.clientArray' => ['OW2S0SMSGUARD'],
};
$defs{unrelated} = {
    NAME           => 'unrelated',
    TYPE           => 'OTHER',
    '.clientArray' => ['OTHER'],
};

my %module_hash;
FHEM::OW2S0SMSGUARD::Initialize(\%module_hash);

ok(!exists $defs{master_one}{'.clientArray'}, 'reload invalidates the first master client cache');
ok(!exists $defs{master_two}{'.clientArray'}, 'reload invalidates the second master client cache');
ok(exists $defs{unrelated}{'.clientArray'}, 'reload leaves unrelated client caches untouched');

done_testing();
