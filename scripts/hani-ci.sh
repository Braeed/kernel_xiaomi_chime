#!/bin/bash
#
# Compile script for hanikrnl.
#
SECONDS=0 # builtin bash timer
KERNEL_PATH=$PWD
AK3_DIR="$HOME/tc/AnyKernel3"
DEFCONFIG="vendor/chime_defconfig"

# Exports for shits and giggles
export KBUILD_BUILD_VERSION=69
export KBUILD_BUILD_USER=hani
export KBUILD_BUILD_HOST=dungeon

# Install needed tools
if [[ $1 = "-t" || $1 = "--tools" ]]; then
        mkdir toolchain
	cd toolchain

	curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" || exit 1

	chmod -x antman

	echo 'Setting up toolchain in $(PWD)/toolchain'
	bash antman -S --noprogress || exit 1

	echo 'Patch for glibc'
	bash antman --patch=glibc
fi

# Regenerate defconfig file
if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
fi

if [[ $1 = "-b" || $1 = "--build" ]]; then
	PATH=$PWD/toolchain/bin:$PATH
	mkdir -p out
	make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 $DEFCONFIG
	echo -e ""
	echo -e ""
	echo -e "*****************************"
	echo -e "**                         **"
	echo -e "** Starting compilation... **"
	echo -e "**                         **"
	echo -e "*****************************"
	echo -e ""
	echo -e ""
	make O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 -j$(nproc) || exit 1
	fi
