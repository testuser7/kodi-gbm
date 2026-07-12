#!/bin/bash

if [ ! -f /.kodi/userdata/advancedsettings.xml ]; then
    install -D /usr/local/share/kodi/userdata/advancedsettings.xml.template /.kodi/userdata/advancedsettings.xml
fi

exec /usr/local/bin/kodi --standalone "$@"