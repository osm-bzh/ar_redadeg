#! /bin/bash

# exit dès que qqch se passe mal
# set -e

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Installation des paquets de base"
echo ""

apt update
apt install -y lsb-release nano htop iotop multitail zip unzip git wget curl links rsync screen logrotate ca-certificates sudo


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Configuration des locales"
echo ""

echo "choisir fr_FR.UTF-8 UTF-8"
echo "Nécessitera un reboot pour une prise en compte"
read -p "appuyez sur [Entrée] pour continuer"

dpkg-reconfigure locales


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Installation de python"
echo ""

apt install -y python3 python-is-python3 python3-apt


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création du user redadeg"
echo ""

# création de l'utilisateur
adduser redadeg -u 1201 --disabled-password --quiet

# répertoire ssh
mkdir /home/redadeg/.ssh
# clés autorisées
cp ./authorized_keys /home/redadeg/.ssh/
# permissions
chown -R redadeg:redadeg /home/redadeg/.ssh/
chmod 0600 ./home/redadeg/.ssh/*
chmod -R +x /home/redadeg/.ssh/

# bashrc
cp -f bashrc_redadeg /home/redadeg/.bashrc
chown redadeg:redadeg /home/redadeg/.bashrc

# sudo
cp -f sudoers_redadeg /etc/sudoers.d/redadeg


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Permissions sur /data/ --> user redadeg"
echo ""

chown -R redadeg:redadeg /data/


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Configuration de root"
echo ""

cp ./authorized_keys /root/.ssh/
cp -f bashrc_root /root/.bashrc


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Reboot"
echo ""

reboot

