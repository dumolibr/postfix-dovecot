#!/bin/bash -x


# clean up 
find /var/run/ -name '*.pid' -exec rm {} \;
find /var/lib/ -name '*.lock' -exec rm {} \;

# trap stuff when existing
trap "find /var/run/ -name '*.pid' -exec rm {} \;; find /var/lib/ -name '*.lock' -exec rm {} \;; kill -1 -1;kill -12 -1;kill -10 -1;kill -15 -1" SIGHUP SIGINT SIGQUIT SIGTERM

# prepare for ops
[ -f /etc/mailname ] || /bin/hostname > /etc/mailname
touch /var/log/mail.log

[ ! -d "/var/log/clamav" ]  && mkdir "/var/log/clamav" 
chown -R clamav:clamav "/var/log/clamav" 

[ ! -d "/var/lib/postgrey" ]  && mkdir "/var/lib/postgrey"

# create new ssh keys if this is a fresh setup
if [ -f "/etc/ssh/recreate-ssh-keys-bang-bang" ]; then
	/bin/rm /etc/ssh/ssh_host_* 
	dpkg-reconfigure openssh-server
	/bin/rm "/etc/ssh/recreate-ssh-keys-bang-bang"
fi

# start basic services
SERVICES="rsyslog ssh"
for s in $SERVICES;do service $s start;done

# prepare anti-virus
service clamav-freshclam start
freshclam && service clamav-daemon start &

# start antispam/anti-virus services
SERVICES="postgrey spamassassin amavis"
for s in $SERVICES;do service $s start;done

# imap/pop
/usr/sbin/dovecot

# and finally themailserver
service postfix start

# output logs and stay in the foregournd
tail -F /var/log/mail.log

