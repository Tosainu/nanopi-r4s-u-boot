VERSION 0.7

prep:
    FROM ubuntu:kinetic@sha256:1fa7586c0f10cc7ce7ca379ae48bf06776325b9f8e97963ce40803a8bcc07dca
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
        curl --no-progress-meter --location https://github.com/ARM-software/arm-trusted-firmware/archive/d557aaec77be42bf16472cc143d38afe4f935ec5.tar.gz -o /tmp/archive.tar.gz && \
        echo '24ca524440d7b9de632eb1acfb92be0f0aa63cba0c2d89677b0f9c18d2ec0840  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
    RUN make CROSS_COMPILE=aarch64-linux-gnu- M0_CROSS_COMPILE=arm-linux-gnueabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)
    SAVE ARTIFACT build/rk3399/release/bl31/bl31.elf /bl31.elf

u-boot:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/u-boot/u-boot/archive/2f4664f5c3edc55b18d8906f256a4c8e303243c0.tar.gz -o /tmp/archive.tar.gz && \
        echo 'e07244f12b9d4c3d86628dd5177769c777706bdf872691cd71fdbfd6df3f87bc  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    COPY +tf-a/bl31.elf .
    COPY nanopi-r4s-rk3399_my_defconfig configs/
    RUN make CROSS_COMPILE=aarch64-linux-gnu- nanopi-r4s-rk3399_my_defconfig && \
        PATH="${PWD}/scripts/dtc:${PATH}" make BINMAN_DEBUG=1 BINMAN_VERBOSE=6 BL31=bl31.elf CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    SAVE ARTIFACT u-boot-rockchip.bin /
