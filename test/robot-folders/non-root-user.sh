#!/bin/bash
set -e

source dev-container-features-test-lib

check "fzirob is in PATH" which fzirob
check "rob_folders_source.sh exists in user home" bash -c "find /home/ubuntu/.local -name 'rob_folders_source.sh' | grep -q ."
check "shell integration registered in user bashrc" grep -qF "rob_folders_source.sh" /home/ubuntu/.bashrc
check "shell integration registered in user zshrc" grep -qF "rob_folders_source.sh" /home/ubuntu/.zshrc
check "local bin in user PATH" grep -qF ".local/bin" /home/ubuntu/.bashrc

reportResults
