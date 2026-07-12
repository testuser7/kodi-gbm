FROM debian:trixie AS builder

ARG KODI_VERSION
ARG KODI_NAME

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt update && apt install -y --no-install-recommends \
    autoconf \
    automake \
    autopoint \
    build-essential \
    ccache \
    cmake \
    default-jre \
    gawk \
    gettext \
    git \
    gperf \
    libasound2-dev \
    libass-dev \
    libbluray-dev \
    libcdio++-dev \
    libcec-dev \
    libcurl4-openssl-dev \
    libdav1d-dev \
    libdisplay-info-dev \
    libdrm-dev \
    libegl1-mesa-dev \
    libexiv2-dev \
    libgbm-dev \
    libgcrypt20-dev \
    libgif-dev \
    libgles2-mesa-dev \
    libinput-dev \
    libiso9660-dev \
    libjpeg62-turbo-dev \
    libkissfft-dev \
    liblcms2-dev \
    liblzo2-dev \
    libmicrohttpd-dev \
    libnfs-dev \
    libp8-platform-dev \
    libpython3-dev \
    libsmbclient-dev \
    libspdlog-dev \
    libsqlite3-dev \
    libtag-dev \
    libtinyxml-dev \
    libtinyxml2-dev \
    libtool \
    libunistring-dev \
    libva-dev \
    libxkbcommon-dev \
    libxslt1-dev \
    lsb-release \
    mold \
    meson \
    nasm \
    nlohmann-json3-dev \
    python3-dev \
    swig \
    unzip \
    zip && \
    useradd -m builder

USER builder

ENV CCACHE_DIR=/var/cache/ccache
ENV CMAKE_INSTALL_DO_STRIP=1 

RUN git clone --branch ${KODI_VERSION}-${KODI_NAME} --depth 1 https://github.com/xbmc/xbmc.git /home/builder/kodi

WORKDIR /home/builder/kodi-build

RUN --mount=type=cache,target=/var/cache/kodi-download,uid=1000,gid=1000 \
    cmake ../kodi \
        -G Ninja \
        -DTARBALL_DIR=/var/cache/kodi-download \
        -DCMAKE_C_FLAGS="-w" \
        -DCMAKE_CXX_FLAGS="-w" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCORE_PLATFORM_NAME=gbm \
        -DAPP_RENDER_SYSTEM=gles \
        -DENABLE_INTERNAL_FFMPEG=ON \
        -DENABLE_INTERNAL_CROSSGUID=ON \
        -DENABLE_INTERNAL_FLATBUFFERS=ON \
        -DENABLE_AIRTUNES=OFF \
        -DENABLE_ALSA=ON \
        -DENABLE_AVAHI=OFF \
        -DENABLE_BLURAY=ON \
        -DENABLE_CEC=ON \
        -DENABLE_DBUS=OFF \
        -DENABLE_DVDCSS=ON \
        -DENABLE_EGL=ON \
        -DENABLE_EVENTCLIENTS=ON \
        -DENABLE_MDNS=OFF \
        -DENABLE_MICROHTTPD=ON \
        -DENABLE_MOLD=ON \
        -DENABLE_MYSQLCLIENT=OFF \
        -DENABLE_NFS=ON \
        -DENABLE_OPTICAL=OFF \
        -DENABLE_PLIST=OFF \
        -DENABLE_SMBCLIENT=ON \
        -DENABLE_SNDIO=OFF \
        -DENABLE_UDEV=ON \
        -DENABLE_UPNP=OFF \
        -DENABLE_VAAPI=ON \
        -DENABLE_VDPAU=OFF \
        -DENABLE_XSLT=ON \
        -DENABLE_LIRCCLIENT=OFF \
        -DENABLE_BLUETOOTH=OFF \
        -DENABLE_PIPEWIRE=OFF \
        -DENABLE_PULSEAUDIO=OFF \
        -DENABLE_TESTING=OFF

RUN --mount=type=cache,target=/var/cache/kodi-download,uid=1000,gid=1000 \
    --mount=type=cache,target=/var/cache/ccache,uid=1000,gid=1000 \
    cmake --build . -j$(nproc)

RUN DESTDIR=/tmp/kodi-build cmake --install .

WORKDIR /home/builder/addons-build

RUN cmake ../kodi/cmake/addons \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="-w" \
        -DCMAKE_CXX_FLAGS="-w" \
        -DADDONS_TO_BUILD="inputstream.adaptive" \
        -DCORE_SOURCE_DIR=/home/builder/kodi \
        -DPACKAGE_ZIP=OFF

RUN --mount=type=cache,target=/var/cache/ccache,uid=1000,gid=1000 \
    cmake --build . -j$(nproc)

RUN --mount=type=cache,target=/var/cache/ccache,uid=1000,gid=1000 \
    ccache -p && ccache -s

FROM debian:trixie-slim

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt update && apt install -y --no-install-recommends \
    intel-media-va-driver \
    libasound2t64 \
    libass9 \
    libbluray2 \
    libcdio++1t64 \
    libcec7 \
    libcurl4t64 \
    libdate-tz3 \
    libdav1d7 \
    libdisplay-info2 \
    libegl1 \
    libexiv2-28 \
    libfmt10 \
    libfstrcmp0 \
    libgbm1 \
    libgif7 \
    libgles2 \
    libinput10 \
    libiso9660-12 \
    libkissfft-float131 \
    liblzo2-2 \
    libmicrohttpd12t64 \
    libnfs14 \
    libpcre2-8-0 \
    libpython3.13 \
    libsmbclient0 \
    libspdlog1.15-fmt10 \
    libsqlite3-0 \
    libtag2 \
    libtinyxml2-11 \
    libtinyxml2.6.2v5 \
    libunistring5 \
    libva-drm2 \
    libva-x11-2 \
    libxkbcommon0 \
    libxslt1.1 \
    python3-pil \
    python3-pycryptodome && \
    rm -f /var/log/dpkg.log /var/log/apt/*.log && \
    useradd kodi && mkdir /.kodi && chown kodi:kodi /.kodi

COPY --from=builder /tmp/kodi-build/usr/local/bin/ /usr/local/bin/
COPY --from=builder /tmp/kodi-build/usr/local/lib/ /usr/local/lib/
COPY --from=builder /tmp/kodi-build/usr/local/share/ /usr/local/share/
COPY --from=builder /home/builder/addons-build/build/depends/lib/ /usr/local/lib/
COPY --from=builder /home/builder/addons-build/build/depends/share/ /usr/local/share/
COPY advancedsettings.xml /usr/local/share/kodi/userdata/advancedsettings.xml.template

USER kodi

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENV KODI_DATA="/.kodi" \
    CRASHLOG_DIR="/tmp" \
    KODI_TEMP="/tmp/.kodi/temp" \
    XDG_CACHE_HOME="/tmp/.cache"

EXPOSE 8080
EXPOSE 9090
EXPOSE 9777/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--windowing=gbm", "--audio-backend=alsa", "--logging=console"]
