FROM ubuntu:mantic@sha256:f0bb9ee844f7adb284ac036a15469062adbe3a4458c06680216ed73df231cb31 as base
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bc bison ca-certificates coreutils curl flex gcc gcc-aarch64-linux-gnu \
        gcc-arm-linux-gnueabi gzip libssl-dev make patch python3-dev python3-pyelftools \
        python3-setuptools swig tar && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /work


FROM base as build-tf-a
RUN --mount=type=tmpfs,target=/tmp \
    curl --no-progress-meter --location https://github.com/ARM-software/arm-trusted-firmware/archive/01582a78d26912071f571bd763827ecf47e9becc.tar.gz -o /tmp/archive.tar.gz && \
    echo '91d880ba98feba71f869c18635dccd743d23fda84ff7cb18d32667283fefe7b6  /tmp/archive.tar.gz' | sha256sum -c && \
    tar xf /tmp/archive.tar.gz --strip-components=1
RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
RUN make CROSS_COMPILE=aarch64-linux-gnu- M0_CROSS_COMPILE=arm-linux-gnueabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)


FROM scratch as tf-a
COPY --from=build-tf-a /work/build/rk3399/release/bl31/bl31.elf /


FROM base as build-u-boot
RUN --mount=type=tmpfs,target=/tmp \
    curl --no-progress-meter --location https://github.com/u-boot/u-boot/archive/be2abe73df58a35da9e8d5afb13fccdf1b0faa8e.tar.gz -o /tmp/archive.tar.gz && \
    echo '7292fc281127f1c797045296c2b55934322a7fdda9c15368b5b510b625e37337  /tmp/archive.tar.gz' | sha256sum -c && \
    tar xf /tmp/archive.tar.gz --strip-components=1
COPY --from=tf-a /bl31.elf .
COPY nanopi-r4s-rk3399_my_defconfig configs/
RUN make CROSS_COMPILE=aarch64-linux-gnu- nanopi-r4s-rk3399_my_defconfig && \
    PATH="${PWD}/scripts/dtc:${PATH}" make BINMAN_DEBUG=1 BINMAN_VERBOSE=6 BL31=bl31.elf CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)


FROM scratch as u-boot
COPY --from=build-u-boot /work/u-boot-rockchip.bin /
