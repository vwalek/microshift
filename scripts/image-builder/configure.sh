#!/bin/bash
set -exo pipefail

OSVERSION=$(awk -F: '{print $5}' /etc/system-release-cpe)

sudo dnf install -y git osbuild-composer composer-cli ostree rpm-ostree \
    cockpit-composer cockpit-machines bash-completion podman runc genisoimage \
    createrepo yum-utils selinux-policy-devel jq wget lorax rpm-build \
    containernetworking-plugins

sudo systemctl enable osbuild-composer.socket --now
sudo systemctl enable cockpit.socket --now
sudo firewall-cmd --add-service=cockpit --permanent

# The mock utility comes from the EPEL repository
sudo dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OSVERSION}.noarch.rpm"
sudo dnf install -y mock caddy tomcli
sudo usermod -a -G mock "$(whoami)"

# Verify umask and home directory permissions
TEST_FILE=$(mktemp /tmp/configure-perm-test.XXXXX)

touch "${TEST_FILE}.file"
mkdir "${TEST_FILE}.dir"
HOME_PERM=$(stat -c 0%a ~)
FILE_PERM=$(stat -c 0%a "${TEST_FILE}.file")
DIR_PERM=$(stat -c 0%a "${TEST_FILE}.dir")

# Set the Correct Permissions for osbuild-composer
[ "${HOME_PERM}" -lt 0711 ]  && chmod go+x ~

if [ "${FILE_PERM}" -lt 0644 ] || [ "${DIR_PERM}" -lt 0711 ] ; then
    echo "Check ${TEST_FILE}.dir permissions. The umask setting must allow execute to group/others"
    echo "Check ${TEST_FILE}.file permissions. The umask setting must allow read to group/others"    
    exit 1
fi

rm -rf "${TEST_FILE}"*
