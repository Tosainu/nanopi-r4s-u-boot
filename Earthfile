VERSION 0.7

prep:
    FROM ubuntu:kinetic@sha256:e322f4808315c387868a9135beeb11435b5b83130a8599fd7d0014452c34f489
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
        curl --no-progress-meter --location https://github.com/ARM-software/arm-trusted-firmware/archive/2503c8f3204c60013de8caa2e165b2875ad735e5.tar.gz -o /tmp/archive.tar.gz && \
        echo 'f19f5e6c6795823d37b2c3ca6d7e6854d32a43a4a3e772053067805f562a6f29  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
    RUN make CROSS_COMPILE=aarch64-linux-gnu- M0_CROSS_COMPILE=arm-linux-gnueabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)
    SAVE ARTIFACT build/rk3399/release/bl31/bl31.elf /bl31.elf

u-boot:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/u-boot/u-boot/archive/05aa6516c6bb419d01d69fac457c0de563bfd694.tar.gz -o /tmp/archive.tar.gz && \
        echo 'dabc514c90d98451a3e11db226eb2ec98a043d081e969a137944b4c7cc665036  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    COPY +tf-a/bl31.elf .
    COPY nanopi-r4s-rk3399_my_defconfig configs/
    RUN make CROSS_COMPILE=aarch64-linux-gnu- nanopi-r4s-rk3399_my_defconfig && \
        PATH="${PWD}/scripts/dtc:${PATH}" make BINMAN_DEBUG=1 BINMAN_VERBOSE=6 BL31=bl31.elf CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    SAVE ARTIFACT u-boot-rockchip.bin /
