VERSION 0.6

prep:
    FROM ubuntu:jammy@sha256:27cb6e6ccef575a4698b66f5de06c7ecd61589132d5a91d098f7f3f9285415a9
    RUN \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            bc bison ca-certificates coreutils curl flex gcc gzip libc6-dev libssl-dev make \
            python3-dev python3-setuptools swig tar xz-utils && \
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
        curl --no-progress-meter --location https://github.com/ARM-software/arm-trusted-firmware/archive/f4d8ed50d27687d437e6885d2b6445a720ae9f69.tar.gz -o /tmp/archive.tar.gz && \
        echo 'c5b50c8cea4c58f590b64db47f035d9e70712dfad571f51a38592a63604730bf  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
    RUN sed -i 's!\s\(-Wl,\)\?--fatal-warnings\b!!g' Makefile
    RUN make CROSS_COMPILE=/opt/arm/aarch64-none-elf/bin/aarch64-none-elf- M0_CROSS_COMPILE=/opt/arm/arm-none-eabi/bin/arm-none-eabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)
    SAVE ARTIFACT build/rk3399/release/bl31/bl31.elf /bl31.elf

u-boot:
    FROM +prep
    RUN --mount=type=tmpfs,target=/tmp \
        curl --no-progress-meter --location https://github.com/u-boot/u-boot/archive/adcee0791f3318ead9b22879e2ce9409f400dcab.tar.gz -o /tmp/archive.tar.gz && \
        echo '626e75bbed0a1e346f4726bb8918fc5d4ee2cac2bfa760c8cd3a85f0b912a2eb  /tmp/archive.tar.gz' | sha256sum -c && \
        tar xf /tmp/archive.tar.gz --strip-components=1
    COPY +tf-a/bl31.elf .
    RUN make CROSS_COMPILE=/opt/arm/aarch64-none-elf/bin/aarch64-none-elf- nanopi-r4s-rk3399_defconfig && \
        BL31=bl31.elf PATH="${PWD}/scripts/dtc:${PATH}" make CROSS_COMPILE=/opt/arm/aarch64-none-elf/bin/aarch64-none-elf- -j$(nproc)
    SAVE ARTIFACT u-boot-rockchip.bin /
