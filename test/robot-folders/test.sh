#!/bin/bash
set -e

source dev-container-features-test-lib

ROB_SOURCE=/opt/pipx/venvs/robot-folders/bin/rob_folders_source.sh

check "fzirob is in PATH" which fzirob
check "rob_folders_source.sh exists" test -f "${ROB_SOURCE}"
check "fzirob is available after sourcing" bash -c "source ${ROB_SOURCE} && command -v fzirob > /dev/null"
check "shell integration registered in bash.bashrc" grep -qF "rob_folders_source.sh" /etc/bash.bashrc
check "shell integration registered in zshrc" grep -qF "rob_folders_source.sh" /etc/zsh/zshrc
check "fzirob available in zsh" zsh -c "source /etc/zsh/zshrc && command -v fzirob > /dev/null"

reportResults
