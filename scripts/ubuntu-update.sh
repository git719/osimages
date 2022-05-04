#!/bin/bash -eu
# ubuntu-update.sh

echo "==> Disabling apt.daily.service & apt-daily-upgrade.service"
systemctl stop apt-daily.timer apt-daily-upgrade.timer
systemctl mask apt-daily.timer apt-daily-upgrade.timer
systemctl stop apt-daily.service apt-daily-upgrade.service
systemctl mask apt-daily.service apt-daily-upgrade.service
systemctl daemon-reload

echo "==> Updating list of repositories"
plog=/root/packer.log
# Checks work around a known time sync issue
AptGet="apt-get -y -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false"
$AptGet update > $plog
printf "\n\n\n" >> $plog
if [[ $UPDATE =~ true || $UPDATE =~ 1 ]]; then
    echo "==> Upgrading packages"
    Opt="-o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'"
    $AptGet $Opt dist-upgrade >> $plog
fi
printf "\n\n\n" >> $plog
$AptGet install --no-install-recommends build-essential linux-headers-generic ssh curl vim dkms >> $plog

echo "==> Removing the release upgrader"
$AptGet purge ubuntu-release-upgrader-core >> $plog
rm -rf /var/lib/ubuntu-release-upgrader
rm -rf /var/lib/update-manager

if [[ $DISABLE_IPV6 =~ true || $DISABLE_IPV6 =~ 1 ]]; then
    echo "==> Disabling IPv6"
    sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub
fi

echo "==> Streamline grub boot settings"
sed -i '/^GRUB_TIMEOUT=/aGRUB_RECORDFAIL_TIMEOUT=0' /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet nosplash"/' /etc/default/grub
sed -i '/^GRUB_HIDDEN_TIMEOUT=/d' /etc/default/grub
update-grub

UbuntuVer=$(hostnamectl | awk '/Operating System/ {print $4}')
UbuntuVer=${UbuntuVer%%.*}
if [[ "$UbuntuVer" -ge "20" ]]; then
    echo "==> Uninstalling all SNAP installs, including its daemon"
    sudo snap remove lxd
    sudo snap remove core18
    Ver=$(snap list | awk '/^snapd/ {print $3}')
    sudo umount /snap/snapd/$Ver
    $AptGet purge snapd >> $plog
fi

echo "==> Shutting down the SSHD service and rebooting..."
# This reboot is required because the kernel and grub were updated
sudo systemctl stop sshd
nohup shutdown -r now < /dev/null > /dev/null 2>&1 &
sleep 120

exit 0
