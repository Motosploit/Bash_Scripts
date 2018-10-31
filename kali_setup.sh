#!/bin/bash
# Script to use when standing up a new kali box, it installs virtualbox guest additions, updates, adds a new user, and installs a bunch of tools not included out of the box.
# must run as sudo
# supply argument of user you want
echo Example Usage: ie: sudo ./kali_setup.sh nottoor

# todo: 
# add firewall hardening using ufw
# cronjob for hourly updates/upgrades
# use ssh keys instead of username/password if needed

#install vbox guest additions
#insert guest additions CD
cd /media/cdrom/
cp -r * /tmp/
cd /tmp/
./VBoxLinuxAdditions.run

cd
user=$1
#Add new user  
adduser $user 
#adduser $user
#useradd -g users -d /home/$user -s /bin/bash -m -p $(echo mypasswd | openssl passwd -1 -stdin) $user 

#Give new user sudo privileges 
#User privilege specification 
echo "$user ALL=(ALL:ALL) ALL" >> /etc/sudoers

#Disable SSH for Root 
echo "PermitRootLogin no" >> /etc/ssh/sshd_config 
#didnt work
/etc/init.d/ssh restart 

#import SSH keys

#make sure sources list is ok
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list
#update everything
sudo apt-get update -y
sudo apt-get upgrade -y

# install Veil, payload tool
apt-get install veil -y
# install datasploit, OSINT tool
apt-get install datasploit -y
# install crackmapexec. post exploitation tool
# https://github.com/byt3bl33d3r/CrackMapExec
apt-get install crackmapexec -y
# install discover, OSINT tool
# https://github.com/leebaird/discover
git clone https://github.com/leebaird/discover.git /opt/discover
cd /opt/discover/
./update.sh
cd
# install hsecscan, web app header scanner
# https://github.com/riramar/hsecscan 
git clone https://github.com/riramar/hsecscan.git /opt/hsecscan
# install linkedint, OSINT for LinkedIn
# https://github.com/mdsecactivebreach/LinkedInt 
pip install beautifulsoup4
pip install thready
git clone https://github.com/mdsecactivebreach/LinkedInt.git /opt/LinkedInt
# install WifiSuite, for wireless pentesting
# https://github.com/NickSanzotta/WiFiSuite
apt-get install scapy
git clone https://github.com/NickSanzotta/WiFiSuite.git /opt/WiFiSuite
cd /opt/WiFiSuite
python setup.py install --record install.log
cd
# install spiderfoot, for OSINT
# https://github.com/smicallef/spiderfoot
git clone https://github.com/smicallef/spiderfoot.git /opt/spiderfoot
# install empire, for powershell payloads and post exploitation
# https://github.com/EmpireProject/Empire
git clone https://github.com/EmpireProject/Empire.git /opt/Empire
./opt/empire/setup/install.sh
# install unicorn, av evasion for powershell
git clone https://github.com/trustedsec/unicorn.git /opt/unicorn
# install sublist3r for enumerating subdomains
git clone https://github.com/aboul3la/Sublist3r.git /opt/Sublist3r
cd /opt/Sublist3r
sudo pip install -r requirements.txt
cd

#Change Hostname 
#sudo nano /etc/hosts 
#sudo nano /etc/hostname 
#sudo /etc/init.d/hostname.sh 

#cronjob for hourly updates/upgrades, this isnt working yet
cd /home/$user

#write out current crontab
#echo new cron into cron file
#install new cron file
su -c "crontab -l > mycron; echo '0 * * * * sudo apt-get update && sudo apt-get upgrade -y' >>mycron; crontab mycron; rm mycron" -s /bin/sh $user



