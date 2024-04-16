#!/bin/bash
inotifywait -m -e close_write,moved_to,create /etc/cups | 
while read -r directory events filename; do
	if [ "$filename" = "printers.conf" ]; then
		rm -rf /etc/avahi/services/AirPrint-*.service
		/airprint-generate.py -d /etc/avahi/services
		cp /etc/cups/printers.conf /config/printers.conf
	fi
done
