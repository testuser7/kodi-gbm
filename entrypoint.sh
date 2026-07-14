#!/bin/bash

if [ ! -f /.kodi/userdata/advancedsettings.xml ]; then
    install -D /usr/local/share/kodi/userdata/advancedsettings.xml.template /.kodi/userdata/advancedsettings.xml
fi

if [ "$(id -u)" -eq 0 ]; then
    DEV_GIDS=$(stat -c '%g' /dev/tty[[:alpha:]]* /dev/cec* /dev/dri/* /dev/snd/* /dev/input/* 2>/dev/null | sort -nu | paste -sd, -)
    
    exec setpriv --reuid=kodi --regid=kodi --groups="568,$DEV_GIDS" /usr/local/bin/kodi --standalone "$@"
else
    exec /usr/local/bin/kodi --standalone "$@"
fi
