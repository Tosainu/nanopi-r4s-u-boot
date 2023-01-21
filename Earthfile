VERSION 0.7

prep:
    FROM ubuntu:jammy@sha256:9a0bdde4188b896a372804be2384015e90e3f84906b750c1a53539b585fbbe7f
    RUN \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            bc bison ca-certificates coreutils curl flex gcc gzip libc6-dev libssl-dev make \
            python3-dev python3-pyelftools python3-setuptools swig tar xz-utils && \
        rm -rf /var/lib/apt/lists/*
    ARG TOOLCHAIN_HOST=x86_64
    ARG TOOLCHAIN_VERSION=12.2.rel1
    RUN --mount=type=tmpfs,target=/tmp \
        cd /tmp && \
        curl --no-progress-meter --location --parallel --parallel-immediate \
            -o "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-arm-none-eabi.tar.xz" \
            "https://developer.arm.com/-/media/Files/downloads/gnu/${TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-arm-none-eabi.tar.xz" \
            -o "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-arm-none-eabi.tar.xz.sha256asc" \
            "https://developer.arm.com/-/media/Files/downloads/gnu/${TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-arm-none-eabi.tar.xz.sha256asc" \
            -o "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-aarch64-none-elf.tar.xz" \
            "https://developer.arm.com/-/media/Files/downloads/gnu/${TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-aarch64-none-elf.tar.xz" \
            -o "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-aarch64-none-elf.tar.xz.sha256asc" \
            "https://developer.arm.com/-/media/Files/downloads/gnu/${TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-aarch64-none-elf.tar.xz.sha256asc" && \
        sha256sum --check \
            "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-arm-none-eabi.tar.xz.sha256asc" \
            "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-aarch64-none-elf.tar.xz.sha256asc" && \
        mkdir -p /opt/arm/arm-none-eabi /opt/arm/aarch64-none-elf && \
        tar xf "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-arm-none-eabi.tar.xz" --strip-components=1 -C /opt/arm/arm-none-eabi && \
        tar xf "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_HOST}-aarch64-none-elf.tar.xz" --strip-components=1 -C /opt/arm/aarch64-none-elf
    WORKDIR /work
    SAVE IMAGE --push ghcr.io/tosainu/earthly-nanopi-r4s-u-boot:latest

tf-a:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/ARM-software/arm-trusted-firmware/archive/ba12668a65f9b10bc18f3b49a71999ed5d32714a.tar.gz -o /tmp/archive.tar.gz && \
        echo '061b4cebdb77308d2b7c71a686c3c4fcbbfa533284ac275c9499544b6998d97a  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
    RUN sed -i 's!\s\(-Wl,\)\?--fatal-warnings\b!!g' Makefile
    RUN make CROSS_COMPILE=/opt/arm/aarch64-none-elf/bin/aarch64-none-elf- M0_CROSS_COMPILE=/opt/arm/arm-none-eabi/bin/arm-none-eabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)
    SAVE ARTIFACT build/rk3399/release/bl31/bl31.elf /bl31.elf

u-boot:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/u-boot/u-boot/archive/8c39999acb726ef083d3d5de12f20318ee0e5070.tar.gz -o /tmp/archive.tar.gz && \
        echo '75993c4116b89576e8b03e89633b4b555c3348d5aa6b8ff9b623bab555affe5c  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    COPY +tf-a/bl31.elf .
    COPY nanopi-r4s-rk3399_bootstd_defconfig configs/
    RUN make CROSS_COMPILE=/opt/arm/aarch64-none-elf/bin/aarch64-none-elf- nanopi-r4s-rk3399_bootstd_defconfig && \
        PATH="${PWD}/scripts/dtc:${PATH}" make BINMAN_DEBUG=1 BINMAN_VERBOSE=6 BL31=bl31.elf CROSS_COMPILE=/opt/arm/aarch64-none-elf/bin/aarch64-none-elf- -j$(nproc)
    SAVE ARTIFACT u-boot-rockchip.bin /
