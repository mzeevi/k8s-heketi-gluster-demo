#!/bin/bash
curl -s https://api.github.com/repos/heketi/heketi/releases/latest | grep browser_download_url | grep linux.amd64 | cut -d '"' -f 4 | wget -qi -

for i in `ls | grep heketi | grep .tar.gz`; do tar xvf $i; done
sudo cp heketi/{heketi,heketi-cli} /usr/local/bin
sudo cp heketi/{heketi,heketi-cli} /usr/bin

sudo groupadd --system heketi
sudo useradd -s /sbin/nologin --system -g heketi heketi

sudo ssh-keygen -f /etc/heketi/heketi_key -t rsa -N ''
sudo chown heketi:heketi /etc/heketi/heketi_key*

for i in glfs0 glfs1 glfs2; do
  sshpass -p qwe123 ssh-copy-id -i /etc/heketi/heketi_key.pub -o StrictHostKeyChecking=no root@$i
done

sudo wget -O /etc/heketi/heketi.env https://raw.githubusercontent.com/heketi/heketi/master/extras/systemd/heketi.env
sudo chown -R heketi:heketi /var/lib/heketi /var/log/heketi /etc/heketi

sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

sudo systemctl daemon-reload
sudo systemctl enable --now heketi

ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
sshpass -p qwe123 ssh-copy-id -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no root@localhost

cd ~/projects/ansible
ansible-playbook -i hosts -k heketi.yml -b

heketi-cli topology load --user admin --secret heketi_admin_secret --json=/etc/heketi/topology.json
