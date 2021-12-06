# CUPS-docker

Run a CUPS print server on a remote machine to share USB printers over WiFi. Built primarily to use with Raspberry Pis, but there is no reasol this shouldn't work on `amd64` machines. Tested and confirmed working on a Raspberry Pi 3B+ (`arm/v7`) and Raspberry Pi 4 (`arm64/v8`).

## Usage
```sh
docker run -d -p 631:631 --device /dev/bus/usb --name cups anujdatar/cups
````

### Parameters
- `port` -> default cups network port `631:631`. would not change unless you know what you're doing
- `device` -> used to give docker access to USB printer. Default passes the whole USB bus `/dev/bus/usb`, in case you change the USB port on your device later. change to specific USB port if it will always be fixed, for eg. `/dev/bus/usb/001/005`.

#### Optional parameters
- `name` -> whatever you want to call your docker image. using `cups` in the example above.

**TODO**: make env vars changable by image user. currently set to defaults
Environment variables that can be changed to suit your needs, use the `-e` tag
| # | Parameter | Default | Type | Description |
| - | - | - | - | - |
| 1 | TZ | "America/New_York" | string | Time zone of your server |
| 2 | CUPSADMIN | admin | string | Name of the admin user for server |
| 3 | CUPSPASSWORD | password | string | Password for server admin |

> Note: changing the default username and password is recommended.


## Thanks
Based on the work done by **RagingTiger**: [https://github.com/RagingTiger/cups-airprint](https://github.com/RagingTiger/cups-airprint)
