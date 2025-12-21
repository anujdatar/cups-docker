# CUPS-docker

Modern CUPS (Common Unix Printing System) print server Docker container for sharing USB printers over WiFi. Optimized for 2025 with enhanced security, health checks, and comprehensive printer driver support including **HP LaserJet 1018**.

Built primarily for use with Raspberry Pis as a headless server, but works perfectly on `amd64` machines. Tested and confirmed working on:
- Raspberry Pi 3B+ (`arm/v7`)
- Raspberry Pi 4 (`arm64/v8`)
- x86_64/amd64 systems

## Features (2025 Update)

- ✅ **HP LaserJet 1018 Support** - Pre-configured with `foo2zjs` and `hplip` drivers
- ✅ **Modern Base Image** - Debian Bookworm (stable, up-to-date)
- ✅ **Health Checks** - Built-in container health monitoring
- ✅ **Enhanced Security** - Improved configuration and error handling
- ✅ **Better Logging** - Comprehensive logging with timestamps
- ✅ **Network Discovery** - Avahi/mDNS support for automatic printer discovery
- ✅ **Comprehensive Drivers** - Support for most common printer brands

Container packages available from Docker Hub and Github Container Registry (ghcr.io)
  - Docker Hub Image: `flags8192/cups`
  - GHCR Image: `ghcr.io/flags8192/cups`

## Usage
Quick start with default parameters
```sh
docker run -d -p 631:631 --device /dev/bus/usb --name cups flags8192/cups
```

Customizing your container
```sh
docker run -d --name cups \
    --restart unless-stopped \
    -p 631:631 \
    --device /dev/bus/usb \
    -e CUPSADMIN=admin \
    -e CUPSPASSWORD=admin \
    -e TZ="Europa/Moscow" \
    -v <persistent-config-folder>:/etc/cups \
    flags8192/cups
```
> Note: :P make sure you use valid TZ string, this is just a joke. Also changing the default username and password is highly recommended.

### Parameters and defaults
- `port` -> default cups network port `631:631`. Change not recommended unless you know what you're doing
- `device` -> used to give docker access to USB printer. Default passes the whole USB bus `/dev/bus/usb`, in case you change the USB port on your device later. change to specific USB port if it will always be fixed, for eg. `/dev/bus/usb/001/005`.

#### Optional parameters
- `name` -> whatever you want to call your docker image. using `cups` in the example above.
- `volume` -> adds a persistent volume for CUPS config files if you need to migrate or start a new container with the same settings

Environment variables that can be changed to suit your needs, use the `-e` tag
| # | Parameter       | Default            | Type   | Description                                    |
| - | --------------- | ------------------ | ------ | ---------------------------------------------- |
| 1 | TZ              | "Europa/Moscow"    | string | Time zone of your server (e.g., "Europe/Moscow") |
| 2 | CUPSADMIN       | admin              | string | Name of the admin user for server              |
| 3 | CUPSPASSWORD    | password           | string | Password for server admin                      |
| 4 | CUPS_LOG_LEVEL  | warn               | string | CUPS log level (debug, info, warn, error, none) |

### docker-compose

Modern docker-compose.yml (recommended):
```yaml
version: "3.8"

services:
  cups:
    image: flags8192/cups
    container_name: cups
    restart: unless-stopped
    ports:
      - "631:631/tcp"
      - "5353:5353/udp"  # Avahi/mDNS for network discovery
    devices:
      - /dev/bus/usb:/dev/bus/usb
    environment:
      - CUPSADMIN=admin
      - CUPSPASSWORD=your_secure_password
      - TZ=Europe/Moscow
      - CUPS_LOG_LEVEL=warn
    volumes:
      - cups-config:/etc/cups
    healthcheck:
      test: ["CMD", "lpstat", "-r"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  cups-config:
```

Legacy format (still supported):
```yaml
version: "3"
services:
    cups:
        image: flags8192/cups
        container_name: cups
        restart: unless-stopped
        ports:
            - "631:631"
        devices:
            - /dev/bus/usb:/dev/bus/usb
        environment:
            - CUPSADMIN=admin
            - CUPSPASSWORD=admin
            - TZ="Europe/Moscow"
        volumes:
            - <persistent-config-path>:/etc/cups
```

## HP LaserJet 1018 Setup

This container includes full support for HP LaserJet 1018 printers. The required drivers (`foo2zjs` and `hplip`) are pre-installed.

### Adding HP LaserJet 1018 via Web Interface

1. Access CUPS web interface at `http://your-server-ip:631`
2. Go to **Administration** → **Add Printer**
3. Select your USB printer (should be detected automatically)
4. When prompted for driver:
   - **Option 1 (Recommended)**: Select "HP" → "HP LaserJet 1018" (if available)
   - **Option 2**: Select "HP" → "HP LaserJet 1015" or "HP LaserJet 1020" (compatible models)
   - **Option 3**: Use "HP LaserJet 1018 - CUPS+Gutenprint v5.3.x" if available

### Adding HP LaserJet 1018 via Command Line

```bash
# Enter the container
docker exec -it cups bash

# List available printers
lpinfo -v

# Add the printer (replace /dev/usb/lp0 with your actual device)
lpadmin -p HP-LaserJet-1018 -E -v usb://HP/LaserJet%201018?serial=YOUR_SERIAL \
  -m drv:///sample.drv/generic.ppd \
  -m raw

# Or use the foo2zjs driver directly
lpadmin -p HP-LaserJet-1018 -E -v usb://HP/LaserJet%201018 \
  -m foo2zjs:/HP/LaserJet_1018
```

### Troubleshooting HP LaserJet 1018

If the printer is not detected:
1. Verify USB connection: `lsusb` (should show HP device)
2. Check CUPS logs: `docker logs cups`
3. Ensure printer is powered on and in ready state
4. Try different USB ports or USB cable

If printing fails:
1. Test with a simple print job: `echo "Test" | lp -d HP-LaserJet-1018`
2. Check printer status: `lpstat -p HP-LaserJet-1018 -l`
3. Review CUPS error log: `docker exec cups tail -f /var/log/cups/error_log`

## Server Administration

You should now be able to access CUPS admin server using:
- **IP Address**: `http://192.168.xxx.xxx:631`
- **Hostname** (if mDNS enabled): `http://printer.local:631`
- **Localhost**: `http://localhost:631` (if running locally)

### Default Credentials
- **Username**: `admin` (or your `CUPSADMIN` value)
- **Password**: `password` (or your `CUPSPASSWORD` value)

⚠️ **Security Note**: Always change the default password in production!

### Health Check

The container includes a built-in health check. Monitor container health:
```bash
docker ps  # Check STATUS column
docker inspect cups | grep -A 10 Health
```

## Supported Printers

This container supports a wide range of printers through:
- `printer-driver-all` - Universal printer drivers
- `hplip` - HP printers (including LaserJet 1018)
- `foo2zjs` - HP LaserJet 1018, 1020, and similar models
- `gutenprint` - Canon, Epson, HP, and other brands
- `foomatic` - Additional printer drivers

## Troubleshooting

### Container won't start
- Check logs: `docker logs cups`
- Verify USB device permissions
- Ensure port 631 is not in use: `netstat -tuln | grep 631`

### Printer not detected
- Verify USB connection: `lsusb` inside container
- Check device permissions: `ls -l /dev/bus/usb`
- Restart container: `docker restart cups`

### Printing fails
- Check CUPS error log: `docker exec cups cat /var/log/cups/error_log`
- Verify printer is online and has paper/toner
- Test with simple print: `echo "test" | lp`

## Changelog (2025 Update)

- ✅ Updated to Debian Bookworm
- ✅ Added HP LaserJet 1018 support
- ✅ Implemented health checks
- ✅ Enhanced error handling and logging
- ✅ Improved security configuration
- ✅ Added comprehensive driver support
- ✅ Optimized Docker image layers

## Thanks

Based on the work done by **RagingTiger**: [https://github.com/RagingTiger/cups-airprint](https://github.com/RagingTiger/cups-airprint)
