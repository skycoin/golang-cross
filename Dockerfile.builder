# golang parameters
ARG GO_VERSION
FROM golang:${GO_VERSION}-buster AS base

ARG APT_MIRROR
RUN sed -ri "s/(httpredir|deb).debian.org/${APT_MIRROR:-deb.debian.org}/g" /etc/apt/sources.list \
 && sed -ri "s/(security).debian.org/${APT_MIRROR:-security.debian.org}/g" /etc/apt/sources.list
ENV OSX_CROSS_PATH=/osxcross

FROM base AS osx-sdk
ARG OSX_SDK
ARG OSX_SDK_SUM

COPY ${OSX_SDK}.tar.xz "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"
RUN echo "${OSX_SDK_SUM}" "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz" | sha256sum -c -

FROM base AS osx-cross-base
ARG DEBIAN_FRONTEND=noninteractive

# Install deps
RUN \
    set -x; \
    echo "Starting image build for Debian Stretch" \
 && dpkg --add-architecture arm64 \
 && dpkg --add-architecture armel \
 && dpkg --add-architecture armhf \
 && dpkg --add-architecture i386 \
 && dpkg --add-architecture mips \
 && dpkg --add-architecture mipsel \
 && dpkg --add-architecture powerpc \
 && dpkg --add-architecture ppc64el \
 && apt-get update                  \
 && apt-get install --no-install-recommends -y -q \
        autoconf \
        automake \
        bc \
        binfmt-support \
        binutils-multiarch \
        build-essential \
        clang \
        gcc \
        g++ \
        mingw-w64 \
        crossbuild-essential-arm64 \
        crossbuild-essential-armel \
        crossbuild-essential-armhf \
        crossbuild-essential-mipsel \
        crossbuild-essential-ppc64el \
        devscripts \
        git-core \
        libtool \
        llvm \
        multistrap \
        patch \
        software-properties-common \
        wget \
        xz-utils \
        cmake \
        qemu-user-static \
        openssl \
        libgtk-3-dev \
        libappindicator-3-dev \
 && apt -y autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM osx-cross-base AS osx-cross
ARG OSX_CROSS_COMMIT
WORKDIR "${OSX_CROSS_PATH}"
# install osxcross:
RUN \
    git clone https://github.com/tpoechtrager/osxcross.git . \
 && git checkout -q "${OSX_CROSS_COMMIT}" \
 && rm -rf ./.git

COPY --from=osx-sdk "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ARG OSX_VERSION_MIN
RUN \
    apt-get update \
 && apt-get install --no-install-recommends -y -q \
    autotools-dev \
    binutils-multiarch-dev \
    libxml2-dev \
    lzma-dev \
    libssl-dev \
    zlib1g-dev \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
 && apt -y autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && UNATTENDED=yes OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh

FROM osx-cross-base AS final
LABEL maintainer="Skycoin <skycoin dot com>"
ARG DEBIAN_FRONTEND=noninteractive

COPY --from=osx-cross "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ENV PATH=${OSX_CROSS_PATH}/target/bin:$PATH
