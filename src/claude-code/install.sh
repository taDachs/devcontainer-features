#!/bin/bash
set -e

ensure_npm_on_debian() {
    if command -v npm >/dev/null 2>&1; then
        return
    fi

    # The nvm feature installs npm under a user directory that isn't sourced for
    # root. Try the known locations before falling back to a fresh Node install.
    for nvm_dir in /usr/local/share/nvm /root/.nvm /home/*/.nvm; do
        if [ -s "${nvm_dir}/nvm.sh" ]; then
            . "${nvm_dir}/nvm.sh"
            if command -v npm >/dev/null 2>&1; then
                return
            fi
        fi
    done

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y curl ca-certificates

    # Install Node.js LTS via NodeSource (apt ships versions too old for Claude Code).
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt-get install -y nodejs
    rm -rf /var/lib/apt/lists/*
}

install_on_debian() {
    ensure_npm_on_debian

    if [ "${VERSION}" = "latest" ]; then
        npm install -g @anthropic-ai/claude-code
    else
        npm install -g @anthropic-ai/claude-code@"${VERSION}"
    fi
}

# ******************
# ** Main section **
# ******************

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
# /etc/os-release also defines VERSION; save our feature option before sourcing.
_FEATURE_VERSION="${VERSION}"
. /etc/os-release
VERSION="${_FEATURE_VERSION}"
unset _FEATURE_VERSION

# Get an adjusted ID independent of distro variants
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
else
    echo "Linux distro ${ID} not supported."
    exit 1
fi

# Install packages for appropriate OS
case "${ADJUSTED_ID}" in
    "debian")
        install_on_debian
        ;;
esac
