#!/bin/bash
set -e

source dev-container-features-test-lib

check "claude is in PATH" which claude
check "claude version" claude --version

reportResults
