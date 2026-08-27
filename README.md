# CUPS-docker

Run a CUPS print server on a remote machine to share USB printers over WiFi. Built primarily to use with Raspberry Pis as a headless server, but there is no reason this wouldn't work on `amd64` machines. Tested and confirmed working on a Raspberry Pi 3B+ (`arm/v7`) and Raspberry Pi 4 (`arm64/v8`).

Container packages available from Docker Hub and Github Container Registry (ghcr.io)
  - Docker Hub Image: `anujdatar/cups`
  - GHCR Image: `ghcr.io/anujdatar/cups`

## Usage
Quick start with default parameters
```sh
docker run -d -p 631:631 \
    -v /dev/bus/usb:/dev/bus/usb \
    --device-cgroup-rule='c 189:* rmw' \
    --name cups anujdatar/cups
```

Customizing your container
```sh
docker run -d --name cups \
    --restart unless-stopped \
    -p 631:631 \
    -v /dev/bus/usb:/dev/bus/usb \
    --device-cgroup-rule='c 189:* rmw' \
    -e CUPSADMIN=batman \
    -e CUPSPASSWORD=batcave_password \
    -e TZ="America/Gotham" \
    -v <persistent-config-folder>:/etc/cups \
    anujdatar/cups
```
> Note: :P make sure you use valid TZ string, this is just a joke. Also changing the default username and password is highly recommended.

### Parameters and defaults
- `port` -> default cups network port `631:631`. Change not recommended unless you know what you're doing
- `usb access` -> gives docker access to the USB printer. Prefer a **bind-mount** of the USB bus over `--device`/`devices:`. `--device` snapshots the device node when the container is created, so it goes stale when the printer re-enumerates after a power-cycle and CUPS hangs on _"waiting for printer to become available"_ (see [#15](https://github.com/anujdatar/cups-docker/issues/15)). A bind-mount is a live view, so re-enumerated nodes appear **without restarting the container**:
    - `-v /dev/bus/usb:/dev/bus/usb` -> live view of the whole host USB bus
    - `--device-cgroup-rule='c 189:* rmw'` -> allow access to usbfs (major `189`); the wildcard minor is what survives re-enumeration

#### Optional parameters
- `name` -> whatever you want to call your docker image. using `cups` in the example above.
- `volume` -> adds a persistent volume for CUPS config files if you need to migrate or start a new container with the same settings

Environment variables that can be changed to suit your needs, use the `-e` tag
| # | Parameter    | Default            | Type   | Description                       |
| - | ------------ | ------------------ | ------ | --------------------------------- |
| 1 | TZ           | "America/New_York" | string | Time zone of your server          |
| 2 | CUPSADMIN    | admin              | string | Name of the admin user for server |
| 3 | CUPSPASSWORD | password           | string | Password for server admin         |

### docker-compose
```yaml
version: "3"
services:
    cups:
        image: anujdatar/cups
        container_name: cups
        restart: unless-stopped
        ports:
            - "631:631"
        # bind-mount the USB bus (live view) instead of `devices:` (a create-time
        # snapshot that goes stale when the printer re-enumerates) -- see issue #15
        device_cgroup_rules:
            - 'c 189:* rmw'   # usbfs; wildcard minor survives printer re-enumeration
        environment:
            - CUPSADMIN=batman
            - CUPSPASSWORD=batcave_password
            - TZ="America/Gotham"
        volumes:
            - <persistent-config-path>:/etc/cups
            - /dev/bus/usb:/dev/bus/usb   # live USB view -> hotplug-safe, no restart needed
```

## Server Administration
You should now be able to access CUPS admin server using the IP address of your headless computer/server http://192.168.xxx.xxx:631, or whatever. If your server has avahi-daemon/mdns running you can use the hostname, http://printer.local:631. (IP and hostname will vary, these are just examples)

If you are running this on your PC, i.e. not on a headless server, you should be able to log in on http://localhost:631

## Thanks
Based on the work done by **RagingTiger**: [https://github.com/RagingTiger/cups-airprint](https://github.com/RagingTiger/cups-airprint)
