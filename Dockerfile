FROM archlinux:base-devel AS builder

RUN --mount=type=cache,target=/var/cache/pacman/pkg,sharing=locked \
    --mount=type=cache,target=/var/cache/pacman/sync,sharing=locked \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm ccache

RUN useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo 'CFLAGS="-w '"$CFLAGS"'"' > /etc/makepkg.conf.d/kodi.conf && \
    echo 'CXXFLAGS="-w '"$CXXFLAGS"'"' >> /etc/makepkg.conf.d/kodi.conf && \
    echo 'SRCDEST="/home/builder/source"' >> /etc/makepkg.conf.d/kodi.conf && \
    echo 'MAKEFLAGS="-j$(nproc)"' >> /etc/makepkg.conf.d/kodi.conf && \
    echo "PKGEXT='.pkg.tar'" >> /etc/makepkg.conf.d/kodi.conf && \
    echo 'BUILDENV=(!distcc color ccache check !sign)' >> /etc/makepkg.conf.d/kodi.conf

USER builder

COPY --chown=builder:builder package /home/builder/package

WORKDIR /home/builder/package

ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_ENV_CMAKE_INSTALL_MESSAGE=NEVER
ENV CMAKE_ENV_CMAKE_MESSAGE_LOG_LEVEL=NOTICE

RUN --mount=type=cache,target=/var/cache/pacman/pkg,sharing=locked \
    --mount=type=cache,target=/var/cache/pacman/sync,sharing=locked \
    --mount=type=cache,target=/home/builder/source,uid=1000 \
    --mount=type=cache,target=/home/builder/package/kodi/src,uid=1000 \
    --mount=type=cache,target=/home/builder/.ccache,uid=1000 \
    timeout --signal=INT 14400s \
    makepkg --dir kodi --syncdeps --noconfirm && \
    ccache -s

USER root

RUN --mount=type=cache,target=/var/cache/pacman/pkg,sharing=locked \
    --mount=type=cache,target=/var/cache/pacman/sync,sharing=locked \
    pacman -U --noconfirm kodi/kodi-gbm-*.pkg.tar kodi/kodi-dev-*.pkg.tar

USER builder

RUN --mount=type=cache,target=/var/cache/pacman/pkg,sharing=locked \
    --mount=type=cache,target=/var/cache/pacman/sync,sharing=locked \
    --mount=type=cache,target=/home/builder/source,uid=1000 \
    --mount=type=cache,target=/home/builder/package/kodi-addon-inputstream-adaptive/src,uid=1000 \
    --mount=type=cache,target=/home/builder/.ccache,uid=1000 \
    timeout --signal=INT 14400s \
    makepkg --dir kodi-addon-inputstream-adaptive --syncdeps --noconfirm && \
    ccache -s

FROM archlinux:base

COPY advancedsettings.xml /usr/share/kodi/userdata/advancedsettings.xml.template

RUN --mount=type=cache,target=/var/cache/pacman/pkg,sharing=locked \
    --mount=type=cache,target=/var/cache/pacman/sync,sharing=locked \
    --mount=type=bind,from=builder,source=/home/builder/package,target=/tmp/package \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm intel-media-driver alsa-utils && \
    pacman -U --noconfirm /tmp/package/kodi/kodi-gbm-*.pkg.tar \
    /tmp/package/kodi-addon-inputstream-adaptive/kodi-addon-inputstream-adaptive-*.pkg.tar && \
    rm -f /var/log/pacman.log && \
    useradd kodi && mkdir /.kodi && chown kodi:kodi /.kodi

USER kodi

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENV KODI_DATA="/.kodi" \
    CRASHLOG_DIR="/tmp" \
    KODI_TEMP="/tmp/.kodi/temp" \
    XDG_CACHE_HOME="/tmp/.cache"

EXPOSE 8080
EXPOSE 9090
EXPOSE 9777/udp
EXPOSE 50152

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--windowing=gbm", "--audio-backend=alsa", "--logging=console"]
