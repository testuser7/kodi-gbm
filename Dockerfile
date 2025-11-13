FROM archlinux

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm intel-media-driver kodi-gles kodi-addon-inputstream-adaptive

ADD advancedsettings.xml /root/.kodi/userdata/advancedsettings.xml

CMD /usr/bin/kodi-standalone --windowing=gbm --logging=console --audio-backend=alsa