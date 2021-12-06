FROM ubuntu:focal

# ENV variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ "America/New_York"
ENV CUPSADMIN admin
ENV CUPSPASSWORD password

LABEL maintainer="Anuj Datar <anuj.datar@gmail.com>"
LABEL version="1.0"
LABEL name="anujdatar/cups"
LABEL description="CUPS docker image"
LABEL repository="https://github.com/anujdatar/cups-docker"


# Install dependencies
RUN apt-get update -qq  && apt-get upgrade -qqy && \
    apt-get install -qqy apt-utils usbutils \
    cups cups-filters \
    printer-driver-all \
    printer-driver-cups-pdf \
    printer-driver-foo2zjs \
    foomatic-db-compressed-ppds \
    openprinting-ppds \
    hpijs-ppds \
    hp-ppd \
    hplip

EXPOSE 631

RUN adduser --home="/home/$CUPSADMIN" \
    --shell="/bin/bash" \
    --disabled-password $CUPSADMIN \
    && echo $CUPSADMIN:$CUPSPASSWORD | chpasswd

RUN usermod -aG lp $CUPSADMIN && \
    usermod -aG lpadmin $CUPSADMIN

RUN /usr/sbin/cupsd && \
    cupsctl --remote-any --remote-admin --share-printers && \
    kill $(cat /var/run/cups/cupsd.pid) && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
        sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
        sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
        sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
        sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
        echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
        echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf


CMD ["/usr/sbin/cupsd", "-f"]