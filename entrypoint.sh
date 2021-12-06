#!/bin/bash -ex

if [ $(grep -ci $CUPSADMIN /etc/shadow) -eq 0 ]; then
        useradd -r -G lpadmin -M $CUPSADMIN

    # add password
    echo $CUPSADMIN:$CUPSPASSWORD | chpasswd

    # add tzdata
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata
fi

exec /usr/sbin/cupsd -f
