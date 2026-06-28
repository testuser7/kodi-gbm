#!/bin/bash

if [ ! -f /.kodi/userdata/advancedsettings.xml ]; then
    install -D /usr/share/kodi/userdata/advancedsettings.xml.template /.kodi/userdata/advancedsettings.xml
fi

exec /usr/bin/kodi --standalone "$@"