#!/bin/bash

#judgement
if [[ -a /etc/supervisor/conf.d/supervisord.conf ]]; then
  exit 0
fi

#supervisor
cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[supervisord]
nodaemon=true

[program:postfix]
command=/opt/postfix.sh

[program:rsyslog]
command=/usr/sbin/rsyslogd -n -c3
EOF

############
#  postfix
############
cat >> /opt/postfix.sh <<EOF
#!/bin/bash
service postfix start
tail -f /var/log/mail.log
EOF
chmod +x /opt/postfix.sh
postconf -e myhostname=$mydestination
postconf -F '*/*/chroot = n'
postconf -e inet_protocols=ipv4
postconf -e 'home_mailbox=Maildir/'
postconf -e disable_vrfy_command=yes
postconf -e 'smtpd_banner=$myhostname Microsoft ESMTP MAIL Service ready'

postconf -e virtual_alias_domains=$mydestination
postconf -e virtual_alias_maps=hash:/etc/postfix/virtual
postconf -e 'smtpd_relay_restrictions=permit_mynetworks reject_unauth_destination'
postconf -e mydestination=localhost

# disable sending
postconf -e default_transport=error
postconf -e relay_transport=error

# catch-all
cat >> /etc/postfix/virtual <<EOF
@$mydestination mail@localhost
EOF
postmap /etc/postfix/virtual
chown mail. -R /var/mail

############
# Enable TLS
############
if [[ -n "$(find /etc/postfix/certs -iname *.crt)" && -n "$(find /etc/postfix/certs -iname *.key)" ]]; then
  # /etc/postfix/main.cf
  postconf -e smtpd_tls_cert_file=$(find /etc/postfix/certs -iname *.crt)
  postconf -e smtpd_tls_key_file=$(find /etc/postfix/certs -iname *.key)
  chmod 400 /etc/postfix/certs/*.*
  postconf -e smtpd_tls_ciphers=high
  postconf -e smtpd_tls_exclude_ciphers=aNULL,MD5
  postconf -e smtpd_tls_security_level=may
  # Preferred syntax with Postfix ≥ 2.5:
  postconf -e smtpd_tls_protocols=!SSLv2,!SSLv3
fi
