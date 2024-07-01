FROM ubuntu:mantic@sha256:fd7fe639db24c4e005643921beea92bc449aac4f4d40d60cd9ad9ab6456aec01 as base
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bc bison ca-certificates coreutils curl flex gcc gcc-aarch64-linux-gnu \
        gcc-arm-linux-gnueabi gzip libssl-dev make patch python3-dev python3-pyelftools \
        python3-setuptools swig tar && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /work


FROM base as build-tf-a
COPY arm-trusted-firmware .
RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
RUN make CROSS_COMPILE=aarch64-linux-gnu- M0_CROSS_COMPILE=arm-linux-gnueabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)


FROM scratch as tf-a
COPY --from=build-tf-a /work/build/rk3399/release/bl31/bl31.elf /


FROM base as configure-u-boot
COPY u-boot .
COPY nanopi-r4s-rk3399_my_defconfig configs/
RUN make CROSS_COMPILE=aarch64-linux-gnu- nanopi-r4s-rk3399_my_defconfig

FROM configure-u-boot as build-u-boot
COPY --from=tf-a /bl31.elf .
RUN PATH="${PWD}/scripts/dtc:${PATH}" make BINMAN_DEBUG=1 BINMAN_VERBOSE=6 BL31=bl31.elf CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

FROM scratch as u-boot
COPY --from=build-u-boot /work/u-boot-rockchip.bin /


FROM configure-u-boot as build-u-boot-defconfig
RUN make CROSS_COMPILE=aarch64-linux-gnu- savedefconfig


FROM scratch as u-boot-defconfig
COPY --from=build-u-boot-defconfig /work/.config /config
COPY --from=build-u-boot-defconfig /work/defconfig /
