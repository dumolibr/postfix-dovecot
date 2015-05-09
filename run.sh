#!/bin/bash -x


# clean up 
find /var/run/ -name '*.pid' -exec rm {} \;
[ -f /etc/mailname ] || /bin/hostname > /etc/mailname

# trap stuff when existing
trap "find /var/run/ -name '*.pid' -exec rm {} \;; kill -1 -1;kill -12 -1;kill -10 -1;kill -15 -1" SIGHUP SIGINT SIGQUIT SIGTERM

# start basic services
SERVICES="rsyslog ssh"
for s in $SERVICES;do service $s start;done

# prepare anti-virus
service clamav-freshclam start
freshclam

# start antispam/anti-virus services
SERVICES="postgrey spamassassin clamav-daemon amavis"
for s in $SERVICES;do service $s start;done

# imap/pop
/usr/sbin/dovecot

# and finally themailserver
service postfix start

# output logs and stay in the foregournd
tail -F /var/log/mail.log

