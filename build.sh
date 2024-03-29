# Script to build for the captivate and zip the package.
# Written by Evan alias ytt3r
# modified by DMORE
#
# HOW COMPILE DMORE KERNEL
#
# Cleaning is done on three levels.
# make clean     Delete most generated files
#                Leave enough to build external modules
# make mrproper  Delete the current configuration, and all generated files
# make distclean Remove editor backup files, patch leftover files and the like

# make dmore_defconfig   (copy dmore_defconfig file on .config kernel configuration file)
# make menuconfig        (if you want midify kernel features)
# ./build.sh             (compile dmore kernel)

# compilated Dmore kernel has saved on /releastools directory



export LOCALVERSION="-1186377" # release JW9
export KBUILD_BUILD_VERSION="rev03"

#export CROSS_COMPILE="/home/dmore/android-kernel/arm-compiler/arm-2009q3/bin/arm-none-eabi-"
#export CROSS_COMPILE="/home/dmore/android-kernel/arm-compiler/android_prebuilt_toolchains/arm-eabi-linaro-4.6.2/bin/arm-eabi-"
#export CROSS_COMPILE="/home/dmore/android-ndk-r8c/toolchains/arm-linux-androideabi-4.6/prebuilt/linux-x86/bin/arm-linux-androideabi-"
#export CROSS_COMPILE="/home/dmore/android-kernel/arm-compiler/android-toolchain-eabi-linaro-4.7.4/bin/arm-eabi-"
#export CROSS_COMPILE="/home/dmore/android-kernel/arm-compiler/arm-cortex_a8-linux-gnueabi-linaro_4.7.4-2013.09/bin/arm-gnueabi-"
export CROSS_COMPILE="/home/dmore/android-kernel/arm-compiler/arm-cortex_a8-linux-gnueabi-linaro_4.7.4-2013.10/bin/arm-cortex_a8-linux-gnueabi-"
if ! [ -e .config ]; then
 make $1
fi


# --- old kernel version release
#export LOCALVERSION="-I9000XWJVB-CL118186"
#export LOCALVERSION="-I9000XWJVH-CL184813"
#export LOCALVERSION="-I9000XXJW4-CL1043937"
#export LOCALVERSION="-I9000XWJW5-CL1045879"
#export LOCALVERSION="-I9000XWJW6-CL1086604"
#export LOCALVERSION="-I9000XWJW7-CL1125830"


if [ -e ./initramfs/lib/modules ]; then
 rm -f ./initramfs/lib/modules/*
fi

#export INSTALL_MOD_PATH=./initramfs
make modules -j`grep 'processor' /proc/cpuinfo | wc -l` 
#make modules_install

#for i in `find initramfs/lib/modules -name "*.ko"`; do
# cp $i ./usr/initrd_files/lib/modules/
#done

find . -type f -name '*.ko' | xargs -n 1 $CROSS_COMPILE"strip" --strip-unneeded
find . -type f -name '*.ko' |xargs cp -t ./initramfs/lib/modules

cp ../initramfs-default-modules/* ./initramfs/lib/modules/
cp drivers/misc/samsung_modemctl/built-in_o_gcc2009 drivers/misc/samsung_modemctl/built-in.o 

make -j`grep 'processor' /proc/cpuinfo | wc -l` 
cp arch/arm/boot/zImage releasetools
cd releasetools
rm -f *.zip
zip -r DMore *
cd ..
echo "Finished."
