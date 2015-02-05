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
postconf -e "home_mailbox = Maildir/"
postconf -e 'smtpd_banner=$myhostname Microsoft ESMTP MAIL Service, Version: 5.0.2195.1600 ready'

postconf -e virtual_alias_domains=$mydestination
postconf -e virtual_alias_maps=hash:/etc/postfix/virtual
postconf -X mydestination

# disable sending
postconf -e default_transport=error
postconf -e relay_transport=error

# catch-all
cat >> /etc/postfix/virtual <<EOF
@$mydestination mail@localhost
EOF
postmap /etc/postfix/virtual

############
# Enable TLS
############
if [[ -n "$(find /etc/postfix/certs -iname *.crt)" && -n "$(find /etc/postfix/certs -iname *.key)" ]]; then
  # /etc/postfix/main.cf
  postconf -e smtpd_tls_cert_file=$(find /etc/postfix/certs -iname *.crt)
  postconf -e smtpd_tls_key_file=$(find /etc/postfix/certs -iname *.key)
  chmod 400 /etc/postfix/certs/*.*
  # /etc/postfix/master.cf
  postconf -M submission/inet="submission   inet   n   -   n   -   -   smtpd"
  postconf -P "submission/inet/syslog_name=postfix/submission"
  postconf -P "submission/inet/smtpd_tls_security_level=encrypt"
  postconf -P "submission/inet/smtpd_sasl_auth_enable=yes"
  postconf -P "submission/inet/milter_macro_daemon_name=ORIGINATING"
  postconf -P "submission/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination"
  postconf -P "submission/inet/content_filter=protective_markings:dummy"
  postconf -e smtpd_tls_ciphers=high
  postconf -e smtpd_tls_exclude_ciphers=aNULL,MD5
  postconf -e smtpd_tls_security_level=may
  # Preferred syntax with Postfix ≥ 2.5:
  postconf -e smtpd_tls_protocols=!SSLv2,!SSLv3
fi
# client TLS
postconf -e smtp_tls_security_level=may
postconf -e smtp_tls_ciphers=high
postconf -e smtp_tls_exclude_ciphers=aNULL,MD5
postconf -e smtp_tls_protocols=!SSLv2,!SSLv3