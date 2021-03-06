#!/bin/bash

# -----
# Usage
# -----
# $ . ak.sh <update|noupdate> <toolchain> <per>



# ------
# Colors
# ------
RED="\033[01;31m"
BLINK_RED="\033[05;31m"
RESTORE="\033[0m"



# ----------
# Parameters
# ----------
# FETCHUPSTREAM: Whether or not to fetch new AK updates
# TOOLCHAIN: Toolchain to compile with
# PERMISSIVE: Force kernel to be permissive
FETCHUPSTREAM=${1}
TOOLCHAIN=${2}
if [[ -n ${3} ]]
then
   PERMISSIVE=true
fi



# ----------
# Directories
# ----------
ANDROID_DIR=${HOME}
RESOURCE_DIR=${ANDROID_DIR}/Kernels
KERNEL_DIR=${RESOURCE_DIR}/AK
ANYKERNEL_DIR=${RESOURCE_DIR}/AK-AK2
ZIP_MOVE=${HOME}/shared/Kernels/angler/AK
PATCH_DIR="${ANYKERNEL_DIR}/patch"
MODULES_DIR="${ANYKERNEL_DIR}/modules"
ZIMAGE_DIR="${KERNEL_DIR}/arch/arm64/boot"



# ---------
# Variables
# ---------
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image.gz"
DTBIMAGE="dtb"
DEFCONFIG="ak_angler_defconfig"
KER_BRANCH=ak-mm-staging
AK_BRANCH=ak-angler-anykernel
BASE_AK_VER="AK"
VER=".066-2.ANGLER."
if [ "${TOOLCHAIN}" == "aosp" ]
then
   TOOLCHAIN_VER="AOSP4.9"
   TOOLCHAIN_DIR=Toolchains/AOSP
elif [ "${TOOLCHAIN}" == "uber4" ]
then
   TOOLCHAIN_VER="UBER4.9"
   TOOLCHAIN_DIR=Toolchains/UBER/4.9
elif [ "${TOOLCHAIN}" == "uber5" ]
then
   TOOLCHAIN_VER="UBER5.4"
   TOOLCHAIN_DIR=Toolchains/UBER/5.4
elif [ "${TOOLCHAIN}" == "uber6" ]
then
   TOOLCHAIN_VER="UBER6.1"
   TOOLCHAIN_DIR=Toolchains/UBER/6.1
elif [ "${TOOLCHAIN}" == "uber7" ]
then
   TOOLCHAIN_VER="UBER7.0"
   TOOLCHAIN_DIR=Toolchains/UBER/7.0
elif [ "${TOOLCHAIN}" == "linaro4.9" ]
then
   TOOLCHAIN_VER="LINARO4.9"
   TOOLCHAIN_DIR=Toolchains/Linaro/4.9
elif [ "${TOOLCHAIN}" == "linaro5.4" ]
then
   TOOLCHAIN_VER="LINARO5.4"
   TOOLCHAIN_DIR=Toolchains/Linaro/5.4
elif [ "${TOOLCHAIN}" == "linaro6.1" ]
then
   TOOLCHAIN_VER="LINARO6.1"
   TOOLCHAIN_DIR=Toolchains/Linaro/6.1
elif [ "${TOOLCHAIN}" == "df-linaro4.9" ]
then
   TOOLCHAIN_VER="DF-LINARO4.9"
   TOOLCHAIN_DIR=Toolchains/Linaro/DF-4.9
elif [ "${TOOLCHAIN}" == "df-linaro5.4" ]
then
   TOOLCHAIN_VER="DF-LINARO5.4"
   TOOLCHAIN_DIR=Toolchains/Linaro/DF-5.4
elif [ "${TOOLCHAIN}" == "df-linaro6.1" ]
then
   TOOLCHAIN_VER="DF-LINARO6.1"
   TOOLCHAIN_DIR=Toolchains/Linaro/DF-6.1
fi
AK_VER="${BASE_AK_VER}${VER}${TOOLCHAIN_VER}"



# -------
# Exports
# -------
export LOCALVERSION=-`echo ${AK_VER}`
export CROSS_COMPILE="${RESOURCE_DIR}/${TOOLCHAIN_DIR}/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=nathan
export KBUILD_BUILD_HOST=chancellor
# Export the COMPILE_LOG variable for other files to use (I currently handle this via .bashrc)
# export LOGDIR=${ANDROID_DIR}/Logs
# export COMPILE_LOG=${LOGDIR}/compile_log_`date +%m_%d_%y`.log


# ---------
# Functions
# ---------
# Clean the out and AnyKernel dirs, reset the AnyKernel dir, and make clean
function clean_all {
   if [ -f "${MODULES_DIR}/*.ko" ]; then
     rm `echo ${MODULES_DIR}"/*.ko"`
   fi
   cd ${ANYKERNEL_DIR}
   rm -rf ${KERNEL}
   rm -rf ${DTBIMAGE}
   git checkout ${AK_BRANCH}
   git reset --hard origin/${AK_BRANCH}
   git clean -f -d -x
   git pull
   cd ${KERNEL_DIR}
   echo
   make clean && make mrproper
}

# Fetch the latest updates
function update_git {
   echo
   cd ${KERNEL_DIR}
   git checkout ${KER_BRANCH}
   git fetch upstream
   git merge upstream/${KER_BRANCH}
   git push
   echo
}

# Make the kernel
function make_kernel {
   echo
   cd ${KERNEL_DIR}
   if [ ${PERMISSIVE} = true ]
   then
      git fetch https://github.com/nathanchance/elite_angler.git
      git cherry-pick dec83f85e94af847184895fd7553e1b720a99a11
      ZIP_MOVE=${HOME}/shared/Kernels/angler/AK/Permissive
   fi
   make ${DEFCONFIG}
   make ${THREAD}
}

# Make the modules
function make_modules {
   if [ -f "${MODULES_DIR}/*.ko" ]; then
      rm `echo ${MODULES_DIR}"/*.ko"`
   fi
   #find $MODULES_DIR/proprietary -name '*.ko' -exec cp -v {} $MODULES_DIR \;
   find ${KERNEL_DIR} -name '*.ko' -exec cp -v {} ${MODULES_DIR} \;
}

# Make the DTB file
function make_dtb {
   ${ANYKERNEL_DIR}/tools/dtbToolCM -v2 -o ${ANYKERNEL_DIR}/${DTBIMAGE} -s 2048 -p scripts/dtc/ arch/arm64/boot/dts/
}

# Make the zip file, remove the previous version and upload it
function make_zip {
   cp -vr ${ZIMAGE_DIR}/${KERNEL} ${ANYKERNEL_DIR}/zImage
   cd ${ANYKERNEL_DIR}
   zip -x@zipexclude -r9 `echo ${AK_VER}`.zip *
   rm  ${ZIP_MOVE}/${BASE_AK_VER}*${TOOLCHAIN_VER}.zip
   mv  `echo ${AK_VER}`.zip ${ZIP_MOVE}
   cd ${KERNEL_DIR}
}



# Clear the terminal
clear



# Time the start of the script
DATE_START=$(date +"%s")



# Show the version of the kernel compiling
echo -e ${RED}
echo -e "-------------------------------------------------------"
echo -e ""
echo -e "      ___    __ __    __ __ __________  _   __________ ";
echo -e "     /   |  / //_/   / //_// ____/ __ \/ | / / ____/ / ";
echo -e "    / /| | / ,<     / ,<  / __/ / /_/ /  |/ / __/ / /  ";
echo -e "   / ___ |/ /| |   / /| |/ /___/ _, _/ /|  / /___/ /___";
echo -e "  /_/  |_/_/ |_|  /_/ |_/_____/_/ |_/_/ |_/_____/_____/";
echo -e ""
echo -e ""
echo -e "-------------------------------------------------------"
echo -e ""
echo -e ""
echo -e ""
echo "---------------"
echo "KERNEL VERSION:"
echo "---------------"
echo -e ""

echo -e ${BLINK_RED}
echo -e ${AK_VER}
echo -e ${RESTORE}

echo -e ${RED}
echo -e "---------------------------------------------"
echo -e "BUILD SCRIPT STARTING AT $(date +%D\ %r)"
echo -e "---------------------------------------------"
echo -e ${RESTORE}



# Clean up
echo -e ${RED}
echo -e "-----------"
echo -e "CLEANING UP"
echo -e "-----------"
echo -e ${RESTORE}
echo -e ""

clean_all



# Update the git
echo -e ""
if [ "${FETCHUPSTREAM}" == "update" ]
then
   echo -e ${RED}
   echo -e "----------------"
   echo -e "UPDATING SOURCES"
   echo -e "----------------"
   echo -e ${RESTORE}

   update_git
fi



# Make the kernel
echo -e ${RED}
echo -e "-------------"
echo -e "MAKING KERNEL"
echo -e "-------------"
echo -e ${RESTORE}

make_kernel
make_dtb
make_modules



# If the above was successful
if [ `ls ${ZIMAGE_DIR}/${KERNEL} 2>/dev/null | wc -l` != "0" ]
then
   BUILD_SUCCESS_STRING="BUILD SUCCESSFUL"


   make_zip


   # Upload
   echo -e ${RED}
   echo -e "------------------"
   echo -e "UPLOADING ZIP FILE"
   echo -e "------------------"
   echo -e ${RESTORE}
   echo -e ""

   . ${HOME}/upload.sh
else
   BUILD_SUCCESS_STRING="BUILD FAILED"
fi



# End the script
echo -e ""
echo -e ${RED}
echo "--------------------"
echo "SCRIPT COMPLETED IN:"
echo "--------------------"

DATE_END=$(date +"%s")
DIFF=$((${DATE_END} - ${DATE_START}))

echo -e "${BUILD_SUCCESS_STRING}!"
echo -e "TIME: $((${DIFF} / 60)) MINUTES AND $((${DIFF} % 60)) SECONDS"

echo -e ${RESTORE}

# Add line to compile log
echo -e "`date +%H:%M:%S`: ${BASH_SOURCE} ${TOOLCHAIN_VER}" >> ${COMPILE_LOG}
echo -e "${BUILD_SUCCESS_STRING} IN $((${DIFF} / 60)) MINUTES AND $((${DIFF} % 60)) SECONDS\n" >> ${COMPILE_LOG}

echo -e "\a"
