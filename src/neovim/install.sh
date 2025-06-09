#!/bin/bash
set -e

install_on_debian() {
    # if USE_PPA is true, install using ppa, else compile from source
    if [[ "${USE_PPA}" == "true" ]]; then
        install_ppa_on_debian
    else
        install_from_source_on_debian
    fi
}

install_ppa_on_debian() {
  export DEBIAN_FRONTEND=noninteractive

  apt-get update -y
  apt-get install -y software-properties-common
  add-apt-repository ppa:neovim-ppa/unstable -y
  apt-get update -y
  apt-get install -y neovim
  rm -rf /var/lib/apt/lists/*
}

install_from_source_on_debian() {
  export DEBIAN_FRONTEND=noninteractive

  apt-get update -y
  apt-get install -y ninja-build gettext cmake curl build-essential git

  cd /tmp/
  git clone https://github.com/neovim/neovim.git
  cd neovim
  git checkout ${TAG}
  make CMAKE_BUILD_TYPE=Release
  make install
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
. /etc/os-release
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
