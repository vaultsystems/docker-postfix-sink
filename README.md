docker-postfix-sink
===================

This postfix server can only receive mail. It never relays mail, it never sends mail. Read your messages with mutt.

docker run -p 25:25 -e mydestination=domain.com -v ~/certs:/etc/postfix/certs -v ~/mail:/var/mail/Maildir --name postfix-sink -d docker-postfix-sink

