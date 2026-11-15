use strict;
use warnings;

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

my $file = shift // '/tmp/00_OW2S0SMSGUARD.live.pm';
my $result = do $file;
die $@ if $@;
die "could not load $file: $!" if !defined $result;
print "$file syntax/load OK\n";
