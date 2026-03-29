#!/bin/bash
set -e

# Append $2 to shell rc file $1 if not already present.
append_to_rc() {
    if ! grep -qF "rob_folders_source.sh" "$1" 2>/dev/null; then
        echo "$2" >> "$1"
    fi
}

install_on_debian() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y pipx python3-venv git zsh
    rm -rf /var/lib/apt/lists/*

    # Prefer installing for the non-root remote user when one exists. This keeps
    # the venv in the user's home and avoids touching global rc files.
    TARGET_USER="${_REMOTE_USER:-}"
    [ -z "${TARGET_USER}" ] || [ "${TARGET_USER}" = "root" ] && TARGET_USER="${_CONTAINER_USER:-root}"
    # Guard against _REMOTE_USER being set to a user that doesn't exist yet.
    if [ "${TARGET_USER}" != "root" ] && ! getent passwd "${TARGET_USER}" >/dev/null 2>&1; then
        echo "Warning: user '${TARGET_USER}' not found, falling back to root install."
        TARGET_USER="root"
    fi

    if [ "${TARGET_USER}" != "root" ]; then
        TARGET_HOME=$(getent passwd "${TARGET_USER}" | cut -d: -f6)

        if ! su - "${TARGET_USER}" -c "pipx show robot-folders >/dev/null 2>&1"; then
            su - "${TARGET_USER}" -c "pipx install robot-folders"
        fi

        # Locate rob_folders_source.sh — path varies by pipx version.
        ROB_SOURCE=$(find "${TARGET_HOME}/.local" -name "rob_folders_source.sh" 2>/dev/null | head -1)
        ROB_SOURCE_LINE="[ -f '${ROB_SOURCE}' ] && source '${ROB_SOURCE}'"

        append_to_rc "${TARGET_HOME}/.bashrc" "${ROB_SOURCE_LINE}"

        touch "${TARGET_HOME}/.zshrc"
        chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.zshrc"
        append_to_rc "${TARGET_HOME}/.zshrc" "${ROB_SOURCE_LINE}"

        # Ensure ~/.local/bin (where pipx puts rob) is in the user's PATH.
        if ! grep -qF ".local/bin" "${TARGET_HOME}/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${TARGET_HOME}/.bashrc"
        fi
        if ! grep -qF ".local/bin" "${TARGET_HOME}/.zshrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${TARGET_HOME}/.zshrc"
        fi
    else
        export PIPX_HOME=/opt/pipx
        export PIPX_BIN_DIR=/usr/local/bin

        if ! pipx show robot-folders >/dev/null 2>&1; then
            pipx install robot-folders
        fi

        ROB_SOURCE="${PIPX_HOME}/venvs/robot-folders/bin/rob_folders_source.sh"
        ROB_SOURCE_LINE="[ -f '${ROB_SOURCE}' ] && source '${ROB_SOURCE}'"

        append_to_rc /etc/bash.bashrc "${ROB_SOURCE_LINE}"

        # /etc/zsh/zshrc is the system-wide rc file on Debian/Ubuntu.
        mkdir -p /etc/zsh
        append_to_rc /etc/zsh/zshrc "${ROB_SOURCE_LINE}"
    fi

    # fzirob is a shell function defined in rob_folders_source.sh, not a pipx entry
    # point. Wrap it as an executable so it is available in PATH without sourcing.
    printf '#!/bin/bash\nset -e\nsource %s\nfzirob "$@"\n' "${ROB_SOURCE}" > /usr/local/bin/fzirob
    chmod +x /usr/local/bin/fzirob
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
