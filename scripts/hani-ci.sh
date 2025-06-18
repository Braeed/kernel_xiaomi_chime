#!/bin/bash
#
# build.sh — Kernel compile script with AOSP Clang + GCC downloader
#

SECONDS=0
KERNEL_PATH=$PWD
AK3_DIR="$HOME/tc/AnyKernel3"
DEFCONFIG="vendor/chime_defconfig"

# Toolchain paths (update after downloading)
CLANG_PATH="$PWD/toolchain/clang"
GCC64_PATH="$PWD/toolchain/GCC-64"
GCC32_PATH="$PWD/toolchain/GCC-32"

# Export build info
export KBUILD_BUILD_VERSION=69
export KBUILD_BUILD_USER=hani
export KBUILD_BUILD_HOST=dungeon
export PATH="$CLANG_PATH/bin:$GCC64_PATH/bin:$GCC32_PATH/bin:$PATH"


# ========== TOOLCHAIN DOWNLOADER ==========
if [[ $1 = "-t" || $1 = "--tools" ]]; then
    mkdir -p toolchain 
    cd toolchain

    # -------- CLANG --------
    # echo "📦 Downloading AOSP Clang (r547379)..."
    # aria2c -x 16 -s 16 -c -o clang.tar.gz \
    #   "https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379/-/archive/15.0/android_prebuilts_clang_host_linux-x86_clang-r547379-15.0.tar.gz" || exit 1
    # mkdir -p clang && tar -xf clang.tar.gz -C clang
    # rm clang.tar.gz
    # echo "✅ Clang extracted to: $(pwd)/clang"
    -------- CLANG --------
    echo "📦 Downloading AOSP Clang (r547379)..."
    aria2c -x 16 -s 16 -c -o clang.tar.gz \
      "https://github.com/liliumproject/clang/releases/download/20250609/lilium_clang-20250609.tar.gz"
    mkdir -p clang && tar -xf clang.tar.gz -C clang
    rm clang.tar.gz
    echo "✅ Clang extracted to: $(pwd)/clang"
    
    # # -------- GCC 64-bit --------
    # echo "📦 Downloading AOSP GCC 64-bit..."
    # aria2c -x 16 -s 16 -c -o gcc64.tar.gz \
    #   "https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/tags/android-12.1.0_r27.tar.gz" || exit 1
    # mkdir -p GCC-64 && tar -xf gcc64.tar.gz -C GCC-64
    # rm gcc64.tar.gz
    # echo "✅ GCC 64-bit extracted."

    # -------- GCC 32-bit --------
    # echo "📦 Downloading AOSP GCC 32-bit..."
    # aria2c -x 16 -s 16 -c -o gcc32.tar.gz \
    #   "https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/refs/tags/android-12.1.0_r27.tar.gz" || exit 1
    # mkdir -p GCC-32 && tar -xzf gcc32.tar.gz -C GCC-32
    # rm gcc32.tar.gz
    # echo "✅ GCC 32-bit extracted."
    


    echo -e "\n🎉 All toolchains downloaded successfully"
    exit 0
fi


# ========== DEFCONFIG REGEN ==========
if [[ $1 = "-r" || $1 = "--regen" ]]; then
    make O=out ARCH=arm64 $DEFCONFIG savedefconfig
    cp out/defconfig arch/arm64/configs/$DEFCONFIG
    echo -e "\n🛠️ Successfully regenerated defconfig at $DEFCONFIG"
    exit 0
fi

# ========== KERNEL BUILD ==========
if [[ $1 = "-b" || $1 = "--build" ]]; then
	# PATH=$PWD/toolchain/clang/bin:$PWD/toolchain/GCC-64/bin:$PWD/toolchain/GCC-32/bin:$PATH
    mkdir -p out
    # echo $PATH
    echo -e "\n📂 Setting up defconfig..."
    make O=out ARCH=arm64 \
        CC=clang \
        CROSS_COMPILE=aarch64-linux-gnu- \
        LD=ld.lld \
        AR=llvm-ar \
        NM=llvm-nm \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        LLVM=1 LLVM_IAS=1 \
        $DEFCONFIG

    echo -e "\n🚀 Starting kernel build..."
    make -j$(nproc --all) O=out ARCH=arm64 \
        CC=clang \
        CROSS_COMPILE=aarch64-linux-gnu- \
        LD=ld.lld \
        AR=llvm-ar \
        NM=llvm-nm \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        LLVM=1 LLVM_IAS=1 \ || exit 1

    echo -e "\n✅ Build completed in $SECONDS seconds."
    exit 0
fi

# ========== HELP ==========
# echo "Usage:"
# echo "  ./build.sh --clang-gcc     # Download AOSP Clang + GCC toolchains"
# echo "  ./build.sh --regen         # Regenerate defconfig"
# echo "  ./build.sh --build         # Start kernel build"
