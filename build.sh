#!/bin/bash

# get current path
reldir=`dirname $0`
cd $reldir
DIR=`pwd`

# Colorize and add text parameters
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
cya=$(tput setaf 6)             #  cyan
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
bldcya=${txtbld}$(tput setaf 6) #  cyan
txtrst=$(tput sgr0)             # Reset

THREADS="16"
DEVICE="$1"

if [ "kang$DEVICE" == "kang" ]
then
   echo "error: missing device name"
   exit
fi

# get current version
MAJOR=$(cat $DIR/vendor/pa/config/pa_common.mk | grep 'PA_VERSION_MAJOR = *' | sed  's/PA_VERSION_MAJOR = //g')
MINOR=$(cat $DIR/vendor/pa/config/pa_common.mk | grep 'PA_VERSION_MINOR = *' | sed  's/PA_VERSION_MINOR = //g')
MAINTENANCE=$(cat $DIR/vendor/pa/config/pa_common.mk | grep 'PA_VERSION_MAINTENANCE = *' | sed  's/PA_VERSION_MAINTENANCE = //g')
VERSION=$MAJOR.$MINOR$MAINTENANCE

# get time of startup
res1=$(date +%s.%N)

# we don't allow scrollback buffer
echo -e '\0033\0143'
clear

echo -e "${cya}Building ${bldcya}RemixPA v$VERSION ${txtrst}";

export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
# set ccache due to your disk space,set it at your own risk
$DIR/prebuilts/misc/linux-x86/ccache/ccache -M 15G

# setup environment
echo -e "${bldblu}Setting up environment ${txtrst}"
. build/envsetup.sh

# lunch device
echo -e ""
echo -e "${bldblu}Lunching device ${txtrst}"
lunch "pa_$DEVICE-userdebug";

fix_count=0
release_flag=0
# excute with vars
echo -e ""
for var in $* ; do
if [ "$var" == "sync" ]
then
   echo -e "${bldblu}Fetching latest sources ${txtrst}"
   if [ -d "$ADDON" ]
   then
      echo -e "fetching add-on repo"
      echo -e "change this at script line 28"
      cd $ADDON
      git pull
      cd $DIR
      echo -e "=============================================="
   fi
   repo sync
   echo -e ""
elif [ "$var" == "clean" ]
then
   echo -e "${bldblu}Clearing previous build info ${txtrst}"
   mka installclean
elif [ "$var" == "allclean" ]
then
   echo -e "${bldblu}Clearing build path ${txtrst}"
   mka clean
elif [ "$var" == "fix" ]
then
   echo -e "skip for remove build.prop"
   fix_count=1
elif [ "$var" == "release" ]
then
   release_flag=1
else
   echo -e "running..."
fi
done

if [ "$fix_count" == "0" ]
then
   echo -e "removing build.prop"
   rm -f $DIR/out/target/product/$DEVICE/system/build.prop
fi

echo -e ""
echo -e "${bldblu}Starting compilation ${txtrst}"

# start compilation
mka bacon
echo -e ""

# finished? get elapsed time
res2=$(date +%s.%N)
echo "${bldgrn}Total time elapsed: ${txtrst}${grn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}"
if [ "$release_flag" == "1" ]
then
   mkdir -p out/target/OTA_INPUT
   echo "copying release file to ota input path"
   cp `cat out/target/product/$DEVICE/romPath` out/target/OTA_INPUT/$DEVICE
fi
