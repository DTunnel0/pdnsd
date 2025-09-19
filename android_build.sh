#!/bin/bash
set -e

NDK_HOME=/home/dutra/android-ndk-r28c
PATH=$PATH:$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin
API_LEVEL=21

ARCHS=(
  "arm64-v8a aarch64-linux-android"
  "armeabi-v7a armv7a-linux-androideabi"
  "x86 i686-linux-android"
  "x86_64 x86_64-linux-android"
)

for entry in "${ARCHS[@]}"; do
  set -- $entry
  ARCH=$1
  TOOLCHAIN_PREFIX=$2

  echo "====================================="
  echo ">> Compilando para $ARCH"
  echo "====================================="

  make clean || true

  ./configure \
    --host=$TOOLCHAIN_PREFIX \
    CC=${TOOLCHAIN_PREFIX}${API_LEVEL}-clang \
    CXX=${TOOLCHAIN_PREFIX}${API_LEVEL}-clang++ \
    CFLAGS="-Os -ffunction-sections -fdata-sections -fPIE -pie" \
    LDFLAGS="-Wl,--gc-sections -Wl,-z,max-page-size=0x4000 -fPIE -pie"

  make -j$(nproc)
  make install DESTDIR=$(pwd)/build/$ARCH

  OUTDIR=$(pwd)/build/$ARCH/usr/local/sbin
  if [ -f "$OUTDIR/pdnsd" ]; then
    mv "$OUTDIR/pdnsd" "$(pwd)/build/$ARCH/libpdnsd.so"
    echo ">> Saída: build/$ARCH/libpdnsd.so"
  else
    echo "!! Erro: binário pdnsd não encontrado em $OUTDIR"
    exit 1
  fi
done

echo "====================================="
echo "Build finalizado com sucesso!"
echo "Saídas em build/<arch>/libpdnsd.so"
