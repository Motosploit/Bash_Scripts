#!/bin/bash
# Script to use when standing up a new kali box, it installs virtualbox guest additions, updates, adds a new user, and installs a bunch of tools not included out of the box.
# must run as sudo

# todo: 
# add firewall hardening using ufw?
# cronjob for hourly updates/upgrades
# use ssh keys instead of username/password if needed

#set user variable
user=$1
#set new hostname variable 
newhostname=$2
#set whoami variable
who=$(whoami)

#check script is run as sudo
if [ root != "$who" ]
then  
	echo Please run script as root.
	exit 
fi

#check user and hostname variable is set
if [ -z "$user" ] || [ -z "$newhostname" ]
then  
	echo Please supply a username and hostname
	echo Example Usage: sudo ./kali_setup.sh username newhostname
	exit 
fi

#install vbox guest additions
#insert guest additions CD
echo Installing virtualbox guest additions.
cd /media/cdrom/
cp -r * /tmp/
cd /tmp/
./VBoxLinuxAdditions.run
echo Guest additions install complete.
#change to root directory
cd

#Change Hostname 
#set variable for current hostname
currenthostname=$(cat /etc/hostname)

#replace currenthostname with newhostname in /etc/hosts and /etc/hostname files
sudo sed -i "s/$currenthostname/$newhostname/g" /etc/hosts
sudo sed -i "s/$currenthostname/$newhostname/g" /etc/hostnamee

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

#cronjob for hourly updates/upgrades, had some issues with this
cd /home/$user
#write out current crontab
#echo new cron into cron file
#install new cron file
su -c "crontab -l > mycron; echo '0 * * * * sudo apt-get update && sudo apt-get upgrade -y' >>mycron; crontab mycron; rm mycron" -s /bin/sh $user

#harden the image,
echo Applying hardening scripts from https://gist.github.com/NitescuLucian/
#chkrootkit examines certain elements of the target system and determines whether they have been tampered with.
sudo apt-get install chkrootkit
updatedb
#check for any users that dont need a password to login
cat /etc/shadow | awk -F: '($2==""){print $1}' > ./no_password_users.txt
cat ./no_password_users.txt
echo Running chkrootkit!
sudo chkrootkit > ./chkrootkit_log.txt
#Lynis is a security auditing tool for Linux, Mac OSX, and UNIX systems. It checks the system and the software configuration, to see if there is any room for improvement in the security defenses.
sudo apt-get install lynis
sudo apt-get -f install
sudo apt-get install lynis
#send lynis logs to file to current working directory
echo Running lynis!
sudo lynis audit system > ./lynis_log.txt
##send open ports file to current working directory
echo "Checking for open ports!"
sudo netstat -tulpn > /tmp/open_ports_log.txt
#information on how to close the open ports
echo Close Unwanted Ports using: iptables -A INPUT -p tcp --dport PORT_NUMBER -j DROP 
#output iptables settings to file in working directory
sudo iptables -L -n -v > ./iptables_log.txt
#display results of iptables check
#cat ./iptables_log.txt
#rkhunter  is  a  shell  script  which carries out various checks on the local system to try and detect known rootkits and malware.
sudo apt-get install rkhunter
sudo rkhunter --update
sudo rkhunter -c
echo "Please check no_password_users.txt, lynis_log.txt, and open_ports_log.txt to check for any additional actions you need to take."

#ask if user wants to reboot so all changes can be applied.
echo "Reboot for changes to take effect, would you like to reboot now? (Y/N)"
read answer
if [ $answer = yes ] || [ $answer = y ] || [ $answer = Yes ] || [ $answer = Y ]
then
	echo Rebooting now
	sudo init 6
	exit
elif [ $answer = no ] || [ $answer = n ] || [ $answer = No ] || [ $answer = N ]
then
	echo "Thanks for using this script!"
	exit
fi
