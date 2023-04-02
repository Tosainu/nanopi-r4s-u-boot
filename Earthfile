VERSION 0.7

prep:
    FROM ubuntu:kinetic@sha256:a82eebb42083a134e009a6b81a7e5d2eecc37112fa8ae40642bd3c5153b7e4f0
    RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            bc bison ca-certificates coreutils curl flex gcc gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi \
            gzip libssl-dev make python3-dev python3-pyelftools python3-setuptools swig tar && \
        rm -rf /var/lib/apt/lists/*
    WORKDIR /work
    SAVE IMAGE --push ghcr.io/tosainu/earthly-nanopi-r4s-u-boot:latest

tf-a:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/ARM-software/arm-trusted-firmware/archive/18459571328c6b09954f4278a86aefc20348f42b.tar.gz -o /tmp/archive.tar.gz && \
        echo '27129603e17c9a122668b519165410a7c7fbed435898710093e0e9279283bfa3  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
    RUN make CROSS_COMPILE=aarch64-linux-gnu- M0_CROSS_COMPILE=arm-linux-gnueabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)
    SAVE ARTIFACT build/rk3399/release/bl31/bl31.elf /bl31.elf

u-boot:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/u-boot/u-boot/archive/6c617e082d181cff0c8d5b2ab8d00f5017cc13e1.tar.gz -o /tmp/archive.tar.gz && \
        echo '776abf4dcdd44f9e94f35c8ab4419069e491e6cfb3735756e3b41557460e129c  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    COPY +tf-a/bl31.elf .
    COPY nanopi-r4s-rk3399_bootstd_defconfig configs/
    RUN make CROSS_COMPILE=aarch64-linux-gnu- nanopi-r4s-rk3399_bootstd_defconfig && \
        PATH="${PWD}/scripts/dtc:${PATH}" make BINMAN_DEBUG=1 BINMAN_VERBOSE=6 BL31=bl31.elf CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    SAVE ARTIFACT u-boot-rockchip.bin /
