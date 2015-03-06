#!/bin/bash

NORMAL_COLOR='\033[0m'
RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
GRAY_COLOR='\033[0;37m'

LOG() {
    COLOR="$1"
    TEXT="$2"
    echo -e "${COLOR}$TEXT ${NORMAL_COLOR}"
}


ERROR_ABORT() {
  if [[ $? != 0 ]]
  then
    LOG $RED_COLOR "compilation aborted\n"
    exit  
  fi
}


ERROR_ABORT_MOVE() {
  if [[ $? != 0 ]]
  then
    $($1)
    LOG $RED_COLOR "compilation aborted for $2 target\n"
    exit  
  fi
}

if [ $# -eq 0 ]
then
  LOG $RED_COLOR "no argument provided."
  LOG $GREEN_COLOR "usage: android_compile <ndk_path>\n"
  exit
fi

export ANDROID_NDK=$1

ARM7=out_android/arm
# Enable it back with SM JIT
# ARM64=out_android/arm64
INTEL64=out_android/x64
INTEL32=out_android/ia32
FATBIN=out_android/android
    
MAKE_INSTALL() {
  TARGET_DIR="out_$1_droid"
  PREFIX_DIR="out_android/$1"
  mv $TARGET_DIR out
  ./configure --prefix=$PREFIX_DIR --static-library --dest-os=android --dest-cpu=$1 --without-snapshot #--engine-mozilla
  ERROR_ABORT_MOVE "mv out $TARGET_DIR" $1
  rm -rf $PREFIX_DIR/bin
  make install
  ERROR_ABORT_MOVE "mv out $TARGET_DIR" $1
  mv out $TARGET_DIR
  
  mv $PREFIX_DIR/bin/libcares.a "$PREFIX_DIR/bin/libcares_$1.a"
  mv $PREFIX_DIR/bin/libchrome_zlib.a "$PREFIX_DIR/bin/libchrome_zlib_$1.a"
  mv $PREFIX_DIR/bin/libhttp_parser.a "$PREFIX_DIR/bin/libhttp_parser_$1.a"
  mv $PREFIX_DIR/bin/libjx.a "$PREFIX_DIR/bin/libjx_$1.a"
  mv $PREFIX_DIR/bin/libv8_nosnapshot.a "$PREFIX_DIR/bin/libv8_nosnapshot_$1.a"
  mv $PREFIX_DIR/bin/libv8_base.a "$PREFIX_DIR/bin/libv8_base_$1.a"
  mv $PREFIX_DIR/bin/libopenssl.a "$PREFIX_DIR/bin/libopenssl_$1.a"
  mv $PREFIX_DIR/bin/libuv.a "$PREFIX_DIR/bin/libuv_$1.a"
  mv $PREFIX_DIR/bin/libsqlite3.a "$PREFIX_DIR/bin/libsqlite3_$1.a"
}


COMBINE() {
  # Enable it back with SM JIT
  # cp "$ARM64/bin/$1_arm64.a" "$FATBIN/bin/"
  cp "$ARM7/bin/$1_arm.a" "$FATBIN/bin/"
  cp "$INTEL64/bin/$1_x64.a" "$FATBIN/bin/"
  cp "$INTEL32/bin/$1_ia32.a" "$FATBIN/bin/"
  ERROR_ABORT
}


mkdir out_arm_droid
# Enable it back with SM JIT
# mkdir out_arm64_droid
mkdir out_x64_droid
mkdir out_ia32_droid
mkdir out_android

rm -rf out

OLD_PATH=$PATH
export TOOLCHAIN=$PWD/android-toolchain-arm
export PATH=$TOOLCHAIN/bin:$OLD_PATH
export AR=arm-linux-androideabi-ar
export CC=arm-linux-androideabi-gcc
export CXX=arm-linux-androideabi-g++
export LINK=arm-linux-androideabi-g++

LOG $GREEN_COLOR "Compiling Android ARM7\n"
MAKE_INSTALL arm

export TOOLCHAIN=$PWD/android-toolchain-arm64
export PATH=$TOOLCHAIN/bin:$OLD_PATH
export AR=aarch64-linux-android-ar
export CC=aarch64-linux-android-gcc
export CXX=aarch64-linux-android-g++
export LINK=aarch64-linux-android-g++

# Enable it back with SM JIT
# LOG $GREEN_COLOR "Compiling Android ARM64\n"
# MAKE_INSTALL arm64

export TOOLCHAIN=$PWD/android-toolchain-intelx64
export PATH=$TOOLCHAIN/bin:$OLD_PATH
export AR=x86_64-linux-android-ar
export CC=x86_64-linux-android-gcc
export CXX=x86_64-linux-android-g++
export LINK=x86_64-linux-android-g++

LOG $GREEN_COLOR "Compiling Android INTEL64\n"
MAKE_INSTALL x64

export TOOLCHAIN=$PWD/android-toolchain-intel
export PATH=$TOOLCHAIN/bin:$OLD_PATH
export AR=i686-linux-android-ar
export CC=i686-linux-android-gcc
export CXX=i686-linux-android-g++
export LINK=i686-linux-android-g++

LOG $GREEN_COLOR "Compiling Android INTEL32\n"
MAKE_INSTALL ia32

LOG $GREEN_COLOR "Preparing FAT binaries\n"
rm -rf $FATBIN
mkdir -p $FATBIN/bin
mv $ARM7/include $FATBIN/

cp deps/mozjs/src/js.msg $FATBIN/include/node/

COMBINE "libcares"
COMBINE "libchrome_zlib"
COMBINE "libhttp_parser"
COMBINE "libjx"
COMBINE "libv8_nosnapshot"
COMBINE "libv8_base"
COMBINE "libopenssl"
COMBINE "libuv"
COMBINE "libsqlite3"

cp src/public/*.h $FATBIN/bin

rm -rf $ARM7
# enable it back with SM
# rm -rf $ARM64 
rm -rf $INTEL32
rm -rf $INTEL64

LOG $GREEN_COLOR "JXcore Android binaries are ready under $FATBIN\n"