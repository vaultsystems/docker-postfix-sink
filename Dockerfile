From ubuntu:trusty
MAINTAINER Christoph Dwertmann

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

# Update
RUN apt-get update && apt-get -y install supervisor postfix

# Add files
ADD assets/install.sh /opt/install.sh

EXPOSE 25

# Run
CMD /opt/install.sh;/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
