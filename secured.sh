#!/bin/bash

# NAME:    Secure.d
# VERSION: 0.2.0
# UPDATED: 01/01/2017

# DESCRIPTION: This script is designed to assist in auditing and
# hardening Red Hat Enterprise Linux 6 security posture. This script
# was designed using guidance and technical excerpts from DISA STIG
# RHEL6 V1R13. 

# WEBSITE: https://www.tonycavella.com/projects/secured
# GITHUB: https://www.github.com/tonycavella/secured

# Copyright (C) 2017 Anthony J. Cavella

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>. 

# -----------------------------------------------------------------------------------


printf "##########################################################################\n"
printf "# Secure.d                                                               #\n"
printf "# Copyright (C) 2017 Tony Cavella                                        #\n"
printf "# This program comes with ABSOLUTELY NO WARRANTY. This is free software, #\n" 
printf "# and you are welcome to redistribute it under certain conditions;       #\n" 
printf "# for details <http://www.gnu.org/licenses/gpl-3.0.html>.                #\n"
printf "##########################################################################\n\n"
sleep 1
printf "DETECTING SYSTEM DETAILS AND SETTING VARIABLES:\n"
if [ -f /etc/redhat-release ]; then
    OS_SIMPLE="RHEL"
    OS_LONG="Red Hat Enterprise Linux"
    printf "Detecting Operating System: [ OK ]\n"
    ARCH_TYPE=`getconf LONG_BIT`
    printf "Detecting System Architecture: [ OK ]\n"
    VER_LONG=$(cat /etc/redhat-release | awk '{print $7}')
    VER_SHORT=${VER_LONG%.*}
    printf "Detecting Operating System Version: [ OK ]\n\n"
else
    printf "Detecting Operating System: [ FAIL ]\n"
    printf "EXIT ON ERROR: OS Detection Failed\n"
    exit 1
fi

WORKING_USER="$(whoami)"
if [ "$WORKING_USER" != root ]; then
    printf "EXIT ON ERROR: Not ROOT User\n"
    exit 1
fi

printf "OS:       $OS_LONG ($OS_SIMPLE)\n"
printf "RELEASE:  $VER_SHORT\n"
printf "VERSION:  $VER_LONG\n"
printf "ARCH:     x$ARCH_TYPE\n"
printf "USER:     $WORKING_USER\n\n"

printf "INITIALIZATION COMPLETED, READY TO PROCEED\n"
read -r -p "Are you ready to start security configuration? [Y/n] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then

# Set root address alias
    read -p "Enter an administrative email address: " ADMIN_EMAIL
    printf "Setting root email alias:\r"
    echo "root: $ADMIN_EMAIL" >> /etc/aliases
    printf "Setting root email alias: [ DONE ]\n"

# Performing YUM updates
    printf "Performing YUM updates: \r"
    ./bin/yum_updates.sh
    printf "Performing YUM updates: [ DONE ]\n"

# Setting SSD parmeters
    printf "Setting SSD parameters: \r"
    ./bin/ssd.sh
    printf "Setting SSD parameters: [ DONE ]\n"

# Setting default RPM permissions
    printf "Setting default RPM permissions: \r"
    ./bin/rpm_perms.sh
    printf "Setting default RPM permissions: [ DONE ]\n"

# Edit /dev/fstab SHM
    printf "Setting proper parameters for /etc/fstab dev_shm: \r"
    ./bin/dev_shm.sh
    printf "Setting proper parameters for /etc/fstab dev_shm: [ DONE ]\n"

# Setting system permissions
    printf "Setting appropriate system permissions: \r"
    ./bin/system_perm.sh
    printf "Setting appropriate system permissions: [ DONE ]\n"

# Setting appropriate UMASK
    printf "Making changes to UMASK: \r"
    ./bin/umask.sh 
    printf "Making changes to UMASK: [ DONE ]\n"

# Configuring system-auth 
    printf "Making changes to system-auth: \r"
    ./bin/sysauth.sh
    printf "Making changes to system-auth: [ DONE ]\n"

# Setting CTL-ALT-DEL functions
    printf "Setting CTL-ALT-DEL default behavior: \r"
    ./bin/ctlaltd.sh
    printf "Setting CTL-ALT-DEL default behavior: [ DONE ]\n"

# Setting DoD warning banner
    printf "Setting DoD Warning banner: \r"
    ./bin/banner.sh
    printf "Setting DoD Warning banner: [ DONE ]\n"


else
    printf "EXITING BY USER REQUEST\n"
    exit 0
fi

yum install -y -q oscap
yum install -y -q scap-security-guide

oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_stig-rhel6-server-upstream --results-arf arf.xml --report report.html /usr/share/xml/scap/ssg/content/ssg-rhel6-ds.xml


exit 0



# Execute external scripts
#./bin/ssd.sh
#./bin/rpm_perms.sh
#./bin/shm.sh
#./bin/system_perm.sh
#./bin/umask.sh
#./bin/sysauth.sh
#./bin/ctlaltd.sh
#./bin/banner.sh

# X-Server / Gnome Settings
printf "Detecting X-Server/Gnome Installation:\r"
sleep 1
printf "Detecting X-Server/Gnome Installation: #\r"
sleep 1
printf "Detecting X-Server/Gnome Installation: ##\r"
sleep 1
printf "Detecting X-Server/Gnome Installation: ###\r"

if [ "$DISPLAY" ]; then
    printf "Detecting X-Server/Gnome Installation: [ FOUND ]\n\n"
    printf "Performing X-Server Changes\n\n"
    yum -y -q GConf2
    ./bin/gconf.sh
else
    printf "Detecting X-Server/Gnome Installation: [ NOT FOUND ]\n\n"
    printf "Skipping X-Server Changes\n\n"
fi



sed -i '/kernel/s/$/ audit=1/' /boot/grub/grub.conf
sed -e 's/all_squash//g' -i /etc/exports
sed -e 's/insecure_locks//g' -i /etc/exports
sed -e 's/active = no/active = yes/g' -i /etc/audisp/plugins.d/syslog.conf
sed -e 's/PASS_MIN_LEN.*/PASS_MIN_LEN 15/g' -i /etc/login.defs
sed -e 's/PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/g' -i /etc/login.defs
sed -e 's/PASS_MAX_DAYS.*/PASS_MAX_DAYS 60/g' -i /etc/login.defs
sed -e 's/PASS_WARN_AGE.*/PASS_WARN_AGE 7/g' -i /etc/login.defs
sed -e 's/INACTIVE.*/INACTIVE=35/g' -i /etc/default/useradd
sed -e 's/ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/g' -i /etc/login.defs
sed -e 's/crypt_style.*/crypt_style = SHA512/g' -i /etc/libuser.conf
sed -e 's/PROMPT=yes/PROMPT=no/g' -i /etc/sysconfig/init
sed -i '/vc/d' /etc/securetty
sed -i '/tty/d' /etc/securetty
sed --follow-symlinks -i 's/\<nullok\>//g' /etc/pam.d/system-auth
echo "05 4 * * * root /usr/sbin/aide --check" >> /etc/crontab
echo "* hard core 0" >> /etc/security/limits.conf
echo "* hard maxlogins 10" >> /etc/security/limits.conf

#cp -f configs/system-auth /etc/pam.d/system-auth <----Depreciated
#chmod 644 /etc/pamd.d/system-auth
cp -f configs/sysctl.conf /etc/sysctl.conf
chmod 644 /etc/sysctl.conf
cp -f configs/sshd_config /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config
cp -f configs/stig.conf /etc/modprobe.d/stig.conf
chmod 644 /etc/modprobe.d/stig.conf

if [ "$ARCH_TYPE" == 64 ]; then
    cp -f configs/audit.rules64 /etc/audit/audit.rules
    chmod 640 /etc/audit/audit.rules
else
    cp -f configs/audit.rules32 /etc/audit/audit.rules
    chmod 640 /etc/audit/audit.rules
fi

rm -rf /etc/hosts.equiv
rm -rf ~/.rhosts
find /home/ -name \*.conf -type f -delete

chown root /boot/grub/grub.conf
chgrp root /boot/grub/grub.conf
chmod 600 /boot/grub/grub.conf 
chown root /etc/gshadow
chgrp root /etc/gshadow
chmod 0000 /etc/gshadow
chown root /etc/shadow
chgrp root /etc/shadow
chmod 0000 /etc/shadow
chown root /etc/passwd
chgrp root /etc/passwd
chmod 0644 /etc/passwd
chown root /etc/group
chgrp root /etc/group
chmod 644 /etc/group
chmod go-w /var/log/audit
chown root /var/log/audit -R

chkconfig autofs off
chkconfig rhnsd off
chkconfig xinetd off 
chkconfig iptables on
chkconfig ip6tables on
chkconfig telent off
chkconfig rsh off
chkconfig rexec off
chkconfig rlogin off
chkconfig ypbind off
chkconfig crond on
chkconfig tftp off
chkconfig avahi-daemon off
chkconfig ntpd on
chkconfig auditd on
chkconfig abrtd off
chkconfig atd off
chkconfig ntpdate off
chkconfig oddjobd off
chkconfig qpidd off
chkconfig rdisc off
chkconfig postfix on
chkconfig netconsole off
chkconfig bluetooth off

service autofs stop
service iptables start
service ip6tables start
service xinetd stop
service ypbind stop
service crond start
service avahi-daemon stop
service ntpd start
service auditd start
service abrtd stop
service atd stop
service ntpdate stop
service oddjobd stop
service qpidd stop
service rdisc stop
service snmpd restart
service nfs restart
service auditd restart
service rhnsd stop
service postfix start
service netconsole stop
service bluetooth stop
service sshd restart

aide --init
cp -f /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

yum install -y oscap
yum install -y scap-security-guide

oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_stig-rhel6-server-upstream --results-arf arf.xml --report report.html /usr/share/xml/scap/ssg/content/ssg-rhel6-ds.xml
