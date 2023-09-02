VERSION 0.7

prep:
    FROM ubuntu:kinetic@sha256:e322f4808315c387868a9135beeb11435b5b83130a8599fd7d0014452c34f489
    RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            bc bison ca-certificates coreutils curl flex gcc gcc-aarch64-linux-gnu \
            gcc-arm-linux-gnueabi gzip libssl-dev make patch python3-dev python3-pyelftools \
            python3-setuptools swig tar && \
        rm -rf /var/lib/apt/lists/*
    WORKDIR /work
    SAVE IMAGE --push ghcr.io/tosainu/earthly-nanopi-r4s-u-boot:latest

tf-a:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/ARM-software/arm-trusted-firmware/archive/5f01b0b116629646dcd5aaf62e94b260c6da08f1.tar.gz -o /tmp/archive.tar.gz && \
        echo '806728a55e425396885de6e821f32eddc996d0c3942c0907e1636e4d560250cf  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
    RUN make CROSS_COMPILE=aarch64-linux-gnu- M0_CROSS_COMPILE=arm-linux-gnueabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)
    SAVE ARTIFACT build/rk3399/release/bl31/bl31.elf /bl31.elf

u-boot:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/u-boot/u-boot/archive/0fe0395922d859730eb7ddfcff6ed8d3ac4b2937.tar.gz -o /tmp/archive.tar.gz && \
        echo 'c0e80c660fc4a3e2f1e25a0f577326476e49231184845d77b345c65c4730c021  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    COPY 0000-revert-regulator-implement-basic-reference-counter.patch .
    RUN patch -Np1 < 0000-revert-regulator-implement-basic-reference-counter.patch
    COPY +tf-a/bl31.elf .
    COPY nanopi-r4s-rk3399_my_defconfig configs/
    RUN make CROSS_COMPILE=aarch64-linux-gnu- nanopi-r4s-rk3399_my_defconfig && \
        PATH="${PWD}/scripts/dtc:${PATH}" make BINMAN_DEBUG=1 BINMAN_VERBOSE=6 BL31=bl31.elf CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    SAVE ARTIFACT u-boot-rockchip.bin /
