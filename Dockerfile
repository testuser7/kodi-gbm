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
    gettext \
    git \
    gperf \
    libasound2-dev \
    libass-dev \
    libbluray-dev \
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
    libgl-dev \
    libinput-dev \
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

WORKDIR /home/builder

ENV CCACHE_DIR=/var/cache/ccache
ENV CMAKE_INSTALL_DO_STRIP=1

COPY disable_power_menu.patch .
COPY gbm_win.patch .

RUN git clone --branch ${KODI_VERSION}-${KODI_NAME} --depth 1 https://github.com/xbmc/xbmc.git kodi && \
    git -C kodi apply ../disable_power_menu.patch && \
    git -C kodi apply ../gbm_win.patch


WORKDIR /home/builder/kodi-build

RUN --mount=type=cache,target=/var/cache/kodi-download,uid=1000,gid=1000 \
    cmake ../kodi \
        -G Ninja \
        -DTARBALL_DIR=/var/cache/kodi-download \
        -DCMAKE_C_FLAGS="-w" \
        -DCMAKE_CXX_FLAGS="-w" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCORE_PLATFORM_NAME=gbm \
        -DAPP_RENDER_SYSTEM=gl \
        -DUSE_LTO=ON \
        -DENABLE_INTERNAL_FFMPEG=ON \
        -DENABLE_INTERNAL_CROSSGUID=ON \
        -DENABLE_INTERNAL_FLATBUFFERS=ON \
        -DENABLE_AIRTUNES=OFF \
        -DENABLE_ALSA=ON \
        -DENABLE_AVAHI=OFF \
        -DENABLE_BLURAY=ON \
        -DENABLE_CAP=OFF \
        -DENABLE_CEC=ON \
        -DENABLE_DBUS=OFF \
        -DENABLE_DVDCSS=ON \
        -DENABLE_EGL=ON \
        -DENABLE_EVENTCLIENTS=ON \
        -DENABLE_ISO9660PP=OFF \
        -DENABLE_MARIADBCLIENT=OFF \
        -DENABLE_MDNS=OFF \
        -DENABLE_MICROHTTPD=ON \
        -DENABLE_MOLD=ON \
        -DENABLE_MYSQLCLIENT=OFF \
        -DENABLE_NFS=ON \
        -DENABLE_OPTICAL=OFF \
        -DENABLE_PLIST=OFF \
        -DENABLE_SMBCLIENT=ON \
        -DENABLE_SNDIO=OFF \
        -DENABLE_UDEV=OFF \
        -DENABLE_UDFREAD=ON \
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
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DCMAKE_C_FLAGS="-w" \
        -DCMAKE_CXX_FLAGS="-w" \
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
        -DADDONS_TO_BUILD="inputstream.adaptive" \
        -DCORE_SOURCE_DIR=/home/builder/kodi \
        -DPACKAGE_ZIP=OFF

RUN --mount=type=cache,target=/var/cache/ccache,uid=1000,gid=1000 \
    cmake --build . -j$(nproc)

RUN cp -r /home/builder/addons-build/build/depends/lib/* /tmp/kodi-build/usr/local/lib/ && \
    cp -r /home/builder/addons-build/build/depends/share/* /tmp/kodi-build/usr/local/share/ && \
    rm -rf /tmp/kodi-build/usr/local/include

RUN --mount=type=cache,target=/var/cache/ccache,uid=1000,gid=1000 \
    ccache -p && ccache -s

FROM debian:trixie-slim

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt update && apt install -y --no-install-recommends \
    ca-certificates \
    intel-media-va-driver \
    libasound2t64 \
    libass9 \
    libbluray2 \
    libcec7 \
    libcurl4t64 \
    libdate-tz3 \
    libdav1d7 \
    libdbus-1-3 \
    libdisplay-info2 \
    libegl1 \
    libexiv2-28 \
    libfmt10 \
    libfstrcmp0 \
    libgbm1 \
    libgif7 \
    libgl1 \
    libgl1-mesa-dri \
    libinput10 \
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
    mesa-va-drivers \
    python3-pil \
    python3-pycryptodome && \
    rm -f /var/log/dpkg.log /var/log/apt/*.log && \
    useradd -u 568 -U kodi && \
    mkdir /.kodi && chown kodi:kodi /.kodi 

COPY --from=builder /tmp/kodi-build/usr/local/ /usr/local/
COPY advancedsettings.xml /usr/local/share/kodi/userdata/advancedsettings.xml.template
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENV KODI_DATA="/.kodi" \
    CRASHLOG_DIR="/var/tmp" \
    KODI_TEMP="/var/tmp/.kodi/temp" \
    XDG_CACHE_HOME="/var/tmp/.cache" \
    HOME="/mnt"

EXPOSE 8080
EXPOSE 9090
EXPOSE 9777/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--windowing=gbm", "--audio-backend=alsa", "--logging=console"]
