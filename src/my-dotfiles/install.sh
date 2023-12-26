#!/bin/bash
set -e

install_on_debian() {
  export DEBIAN_FRONTEND=noninteractive

  package_list="${package_list} \
        stow \
        git \
        ca-certificates \
        fzf"

  apt-get update -y
  apt-get -y install --no-install-recommends ${package_list} 2> >( grep -v 'debconf: delaying package configuration, since apt-utils is not installed' >&2 )
  rm -rf /var/lib/apt/lists/*

  if [ "${USERNAME}" = "root" ]; then
    user_home="/root"
  # Check if user already has a home directory other than /home/${USERNAME}
  elif [ "/home/${USERNAME}" != $( getent passwd $USERNAME | cut -d: -f6 ) ]; then
      user_home=$( getent passwd $USERNAME | cut -d: -f6 )
  else
      user_home="/home/${USERNAME}"
      if [ ! -d "${user_home}" ]; then
          mkdir -p "${user_home}"
          chown ${USERNAME}:${group_name} "${user_home}"
      fi
  fi

  git clone 'https://github.com/taDachs/.punktdateien.git' "${user_home}/.punktdateien"
  pushd "${user_home}/.punktdateien"
  bash ./install.bash
  popd
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
