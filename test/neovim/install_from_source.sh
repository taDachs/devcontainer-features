#!/bin/bash
set -e

source dev-container-features-test-lib

check "nvim is in PATH" which nvim
check "nvim version flag" nvim --version
check "no build artifacts in /tmp" bash -c "! test -d /tmp/neovim"

reportResults
