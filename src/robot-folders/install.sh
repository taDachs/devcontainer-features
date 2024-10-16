#!/bin/bash
set -e

install_on_debian() {
  export DEBIAN_FRONTEND=noninteractive

  apt-get update -y
  apt-get install -y pipx python3-venv git
  export PIPX_HOME=/opt/pipx
  export PIPX_BIN_DIR=/usr/local/bin
  pipx install robot-folders
  rm -rf /var/lib/apt/lists/*

  ROBOT_FOLDERS_PATH=/opt/pipx/venvs/robot-folders

  echo "source ${ROBOT_FOLDERS_PATH}/bin/rob_folders_source.sh" >> /source-robot-folders
  chmod +x /source-robot-folders
  echo "source /source-robot-folders" >> ${HOME}/.bashrc
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
