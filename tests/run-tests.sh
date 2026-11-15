#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
perl "$repo/tests/compile-ow2s0smsguard.pl" "$repo/FHEM/00_OW2S0SMSGUARD.pm"
OW_MODULE_PATH="$repo/FHEM/00_OW2S0SMSGUARD.pm" perl "$repo/tests/test-documentation.pl"
OW_MODULE_PATH="$repo/FHEM/00_OW2S0SMSGUARD.pm" perl "$repo/tests/test-plausibility.pl"
OW_MODULE_PATH="$repo/FHEM/00_OW2S0SMSGUARD.pm" perl "$repo/tests/test-reload-client-cache.pl"

