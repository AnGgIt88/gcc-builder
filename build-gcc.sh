#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Author: Finix-Projects

echo "*****************************************"
echo "* Building Bare-Metal Bleeding Edge GCC *"
echo "*****************************************"

# TODO: Add more dynamic option handling
while getopts a: flag; do
  case "${flag}" in
    a) arch=${OPTARG} ;;
  esac
done

# TODO: Better target handling
case "${arch}" in
  "arm") TARGET="arm-eabi" ;;
  "arm64") TARGET="aarch64-elf" ;;
  "x86") TARGET="x86_64-elf" ;;
esac

export WORK_DIR="$PWD"
export PREFIX="$WORK_DIR/../gcc-${arch}"
export PATH="$PREFIX/bin:/usr/bin/core_perl:$PATH"

echo "||                                                                    ||"
echo "|| Building Bare Metal Toolchain for ${arch} with ${TARGET} as target ||"
echo "||                                                                    ||"

download_resources() {
  echo "Downloading Pre-requisites"
  echo "Cloning binutils"
  git clone https://github.com/bminor/binutils-gdb -b $BINUTILS_BRANCH binutils --depth=1
  echo "Cloning GCC"
  git clone https://github.com/gcc-mirror/gcc -b $GCC_BRANCH gcc --depth=1
  cd ${WORK_DIR}
  echo "Downloaded prerequisites!"
}

build_binutils() {
  cd ${WORK_DIR}
  echo "Building Binutils"
  mkdir build-binutils
  cd build-binutils
  ../binutils/configure --target=$TARGET \
    --prefix="$PREFIX" \
    --with-sysroot \
    --disable-nls \
    --disable-docs \
    --disable-werror \
    --disable-gdb \
    --enable-gold \
    --with-pkgversion="$GCC_NAME BinUtils"
  make CFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" CXXFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" -j$(($(nproc --all) + 2))
  make install -j$(($(nproc --all) + 2))
  cd ../
  echo "Built Binutils, proceeding to next step...."
}

build_gcc() {
  cd ${WORK_DIR}
  echo "Building GCC"
  cd gcc
  ./contrib/download_prerequisites
  echo "NFS-project" > gcc/DEV-PHASE
  cd ../
  mkdir build-gcc
  cd build-gcc
  ../gcc/configure --target=$TARGET \
    --prefix="$PREFIX" \
    --disable-decimal-float \
    --disable-libffi \
    --disable-libgomp \
    --disable-libmudflap \
    --disable-libquadmath \
    --disable-libstdcxx-pch \
    --disable-nls \
    --disable-shared \
    --disable-docs \
    --enable-default-ssp \
    --enable-languages=c,c++ \
    --with-pkgversion="$GCC_NAME GCC" \
    --with-newlib \
    --with-gnu-as \
    --with-gnu-ld \
    --with-sysroot

  make CFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" CXXFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" all-gcc -j$(($(nproc --all) + 2))
  make CFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" CXXFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" all-target-libgcc -j$(($(nproc --all) + 2))
  make install-gcc -j$(($(nproc --all) + 2))
  make install-target-libgcc -j$(($(nproc --all) + 2))
  echo "Built GCC!"
}

download_resources
build_binutils
build_gcc
