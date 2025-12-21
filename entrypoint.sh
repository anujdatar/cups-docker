#!/bin/bash -e

set -o pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

log "Starting CUPS Docker container..."

# Validate environment variables
if [ -z "$CUPSADMIN" ]; then
    log "ERROR: CUPSADMIN environment variable is not set"
    exit 1
fi

if [ -z "$CUPSPASSWORD" ]; then
    log "WARNING: CUPSPASSWORD environment variable is not set, using default"
    CUPSPASSWORD="password"
fi

# Set timezone
if [ -n "$TZ" ]; then
    if [ -f /usr/share/zoneinfo/$TZ ]; then
        ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
        dpkg-reconfigure --frontend noninteractive tzdata 2>/dev/null || true
        log "Timezone set to $TZ"
    else
        log "WARNING: Invalid timezone $TZ, using default"
    fi
fi

# Create CUPS admin user if it doesn't exist
if ! id "$CUPSADMIN" &>/dev/null; then
    log "Creating CUPS admin user: $CUPSADMIN"
    useradd -r -G lpadmin -M -s /usr/sbin/nologin "$CUPSADMIN" || {
        log "ERROR: Failed to create user $CUPSADMIN"
        exit 1
    }
    
    # Set password
    echo "$CUPSADMIN:$CUPSPASSWORD" | chpasswd || {
        log "ERROR: Failed to set password for $CUPSADMIN"
        exit 1
    }
    
    log "CUPS admin user created successfully"
else
    log "CUPS admin user $CUPSADMIN already exists"
    
    # Update password if user exists
    echo "$CUPSADMIN:$CUPSPASSWORD" | chpasswd 2>/dev/null || true
fi

# Restore default CUPS config if user does not have any
if [ ! -f /etc/cups/cupsd.conf ]; then
    log "Restoring default CUPS configuration..."
    cp -rpn /etc/cups-bak/* /etc/cups/ 2>/dev/null || {
        log "WARNING: Failed to restore default CUPS config"
    }
fi

# Ensure CUPS directories exist with correct permissions
mkdir -p /var/spool/cups/tmp
chmod 1777 /var/spool/cups/tmp

# Start dbus if available (required for some printer drivers)
if command -v dbus-daemon >/dev/null 2>&1; then
    log "Starting dbus..."
    dbus-daemon --system --nofork --nopidfile 2>/dev/null &
    sleep 1
fi

# Start avahi-daemon if available (for network printer discovery)
if command -v avahi-daemon >/dev/null 2>&1; then
    log "Starting avahi-daemon..."
    avahi-daemon -D 2>/dev/null || log "WARNING: Failed to start avahi-daemon"
fi

# Verify CUPS configuration
if ! cups-config --serverbin &>/dev/null; then
    log "WARNING: CUPS configuration check failed"
fi

log "Starting CUPS daemon..."
log "CUPS will be available at http://localhost:631"
log "Admin user: $CUPSADMIN"
log "HP LaserJet 1018 support: Enabled (foo2zjs, hplip)"

# Start CUPS in foreground
exec /usr/sbin/cupsd -f
