#!/bin/bash -eu
# ubuntu-setup.sh

SSH_USER=${SSH_USERNAME:-vmuser}

logger "==> Granting $SSH_USER sudo"
echo "$SSH_USER     ALL=(ALL)     NOPASSWD: ALL" >> /etc/sudoers.d/$SSH_USER
chmod 440 /etc/sudoers.d/$SSH_USER
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

logger "==> Installing VirtualBox Guest Additions"
AptGet="apt-get -y -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false"
$AptGet install --no-install-recommends dkms
mount -o loop /home/$SSH_USER/VBoxGuestAdditions.iso /mnt
yes | sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -f /home/$SSH_USER/VBoxGuestAdditions.iso

logger "==> Installing /usr/local/bin/vmnet"
mv /home/$SSH_USER/vmnet /usr/local/bin/
chmod +x /usr/local/bin/vmnet
chown root:root /usr/local/bin/vmnet

logger "==> Enabling vmnet as a systemd service to run on bootup"
cat <<EOF > /etc/systemd/system/vmnet.service
# /etc/systemd/system/vmnet.service
# Set up network for VMs managed by https://github.com/lencap/{vm|vmc} utilities
[Unit]
Description=Runs /usr/local/bin/vmnet
After=network.target
[Service]
ExecStart=/usr/local/bin/vmnet
[Install]
WantedBy=multi-user.target
EOF
chmod 0644 /etc/systemd/system/vmnet.service
systemctl enable vmnet.service

logger "==> Updating SSH settings and $SSH_USER public key"
echo "UseDNS no" >> /etc/ssh/sshd_config
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config
mkdir -pm 700 /home/$SSH_USER/.ssh
cat <<EOF > /home/$SSH_USER/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyIZo/WEpMT8006pKzqHKhNEAPITJCEWj\
LN+cGSg9snFXVljAIQ9CtLo89PJvnfGj8I9VxXPxCUmC8gew/XXxQuExa0XhSSNYDEqM\
yOvlB8KSoYw8tFwNAYaeHw4rbygIgOSn5+g1lLXEf+FPa5JJJAByoxvqXtxZhwiJP2BO\
kp/ULqsy1UGbHFzGsYHkD8ukYINnr8Yob5K3GuvBSZkb4o02ErC0Tj9Xi52vxgSQEKNQ\
s5BOxzb4gtJ7ozArd11xrpmel02bH7mRfrB/Gpsfvb4WXRG9Kiat09T3XjceMAlcmMUG\
QJD0ip1mgN3elTCGpon8K5ZRWGxrF7G8XqnGQQ== vm insecure public key
EOF
chmod 0600 /home/$SSH_USER/.ssh/authorized_keys
chown -R $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh

logger "==> Updating bashrc"
printf "\nalias h='history'\n" >> /root/.bashrc

logger "==> Disabling daily apt unattended updates"
echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic

if test -e /root/.profile && \
   grep -q "^mesg n$" /root/.profile && \
   sed -i "s/^mesg n$/tty -s \\&\\& mesg n/g" /root/.profile; then
    logger "==> Fixed stdin not being a tty"
fi

exit 0
