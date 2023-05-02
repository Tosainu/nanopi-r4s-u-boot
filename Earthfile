VERSION 0.7

prep:
    FROM ubuntu:kinetic@sha256:a9a425d086dbb34c1b5b99765596e2a3cc79b33826866c51cd4508d8eb327d2b
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
        curl --no-progress-meter --location https://github.com/ARM-software/arm-trusted-firmware/archive/d5f19c49baa7f420daf3afa2b79cc977ce2e9c74.tar.gz -o /tmp/archive.tar.gz && \
        echo 'c33e0b0828baa4e09abe25835a976dc1866f685408c1271ee3222d5e8cbb2e78  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
    RUN make CROSS_COMPILE=aarch64-linux-gnu- M0_CROSS_COMPILE=arm-linux-gnueabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)
    SAVE ARTIFACT build/rk3399/release/bl31/bl31.elf /bl31.elf

u-boot:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/u-boot/u-boot/archive/50f64026f7a4c2d0a101c93916e01782e4fbbe7f.tar.gz -o /tmp/archive.tar.gz && \
        echo 'e9ac993f9085b423a5b74bdb92446281ee50a44a9d01e39cbabd16281f700411  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    COPY +tf-a/bl31.elf .
    COPY nanopi-r4s-rk3399_my_defconfig configs/
    RUN make CROSS_COMPILE=aarch64-linux-gnu- nanopi-r4s-rk3399_my_defconfig && \
        PATH="${PWD}/scripts/dtc:${PATH}" make BINMAN_DEBUG=1 BINMAN_VERBOSE=6 BL31=bl31.elf CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    SAVE ARTIFACT u-boot-rockchip.bin /
