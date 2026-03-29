#!/bin/bash
set -e

source dev-container-features-test-lib

check "locale is generated" bash -c "locale -a | grep -qi 'en_US'"
check "LANG configured in /etc/default/locale" grep -qF "LANG=en_US.UTF-8" /etc/default/locale
check "LANG set for non-login shells" grep -qF "LANG=en_US.UTF-8" /etc/profile.d/locale.sh

reportResults
