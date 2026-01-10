FROM alpine:3.23.2@sha256:865b95f46d98cf867a156fe4a135ad3fe50d2056aa3f25ed31662dff6da4eb62 AS base
RUN apk add --no-cache \
  bash \
  bison \
  flex \
  gcc \
  gcc-aarch64-none-elf \
  gcc-arm-none-eabi \
  make \
  musl-dev \
  openssl-dev \
  py3-elftools \
  py3-setuptools \
  python3 \
  python3-dev \
  swig
WORKDIR /work


FROM base AS build-tf-a
COPY arm-trusted-firmware .
RUN sed -i 's!^\(#define\s\+RK3399_BAUDRATE\b\).\+$!\1 1500000!' plat/rockchip/rk3399/rk3399_def.h
RUN make CROSS_COMPILE=aarch64-none-elf- M0_CROSS_COMPILE=arm-none-eabi- PLAT=rk3399 DEBUG=0 bl31 -j$(nproc)


FROM scratch AS tf-a
COPY --from=build-tf-a /work/build/rk3399/release/bl31/bl31.elf /


FROM base AS configure-u-boot
COPY u-boot .
COPY nanopi-r4s-rk3399_my_defconfig configs/
RUN make CROSS_COMPILE=aarch64-none-elf- nanopi-r4s-rk3399_my_defconfig

FROM configure-u-boot AS build-u-boot
COPY --from=tf-a /bl31.elf .
RUN PATH="${PWD}/scripts/dtc:${PATH}" make BINMAN_DEBUG=1 BINMAN_VERBOSE=6 BL31=bl31.elf CROSS_COMPILE=aarch64-none-elf- -j$(nproc)

FROM scratch AS u-boot
COPY --from=build-u-boot /work/u-boot-rockchip.bin /


FROM configure-u-boot AS build-u-boot-defconfig
RUN make CROSS_COMPILE=aarch64-none-elf- savedefconfig


FROM scratch AS u-boot-defconfig
COPY --from=build-u-boot-defconfig /work/.config /config
COPY --from=build-u-boot-defconfig /work/defconfig /
