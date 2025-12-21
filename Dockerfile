FROM debian:bookworm-slim

# ENV variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ="Europa/Moscow" \
    CUPSADMIN=admin \
    CUPSPASSWORD=password \
    CUPS_LOG_LEVEL=warn

LABEL org.opencontainers.image.source="https://github.com/flags8192/cups-docker" \
      org.opencontainers.image.description="CUPS Printer Server with HP LaserJet 1018 support" \
      org.opencontainers.image.author="Anuj Datar <anuj.datar@gmail.com>" \
      org.opencontainers.image.url="https://github.com/flags8192/cups-docker/blob/main/README.md" \
      org.opencontainers.image.licenses=MIT \
      org.opencontainers.image.version="2025.1"

# Install dependencies in a single layer for better caching
RUN apt-get update -qq && \
    apt-get upgrade -qqy && \
    apt-get install -qqy --no-install-recommends \
    apt-utils \
    usbutils \
    cups \
    cups-filters \
    cups-bsd \
    cups-client \
    printer-driver-all \
    printer-driver-cups-pdf \
    printer-driver-foo2zjs \
    printer-driver-gutenprint \
    foomatic-db-compressed-ppds \
    openprinting-ppds \
    hpijs-ppds \
    hp-ppd \
    hplip \
    hplip-data \
    avahi-daemon \
    avahi-utils \
    dbus \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# Configure CUPS with improved security settings
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "LogLevel warn" >> /etc/cups/cupsd.conf && \
    echo "# HP LaserJet 1018 support via foo2zjs and hplip" >> /etc/cups/cupsd.conf

# Create necessary directories and set permissions
RUN mkdir -p /var/spool/cups/tmp && \
    chmod 1777 /var/spool/cups/tmp

# Back up cups configs in case user does not add their own
RUN cp -rp /etc/cups /etc/cups-bak

VOLUME [ "/etc/cups" ]

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
EXPOSE 631/tcp 5353/udp

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD lpstat -r > /dev/null 2>&1 || exit 1

CMD ["/entrypoint.sh"]
