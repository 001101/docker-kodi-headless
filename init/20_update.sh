#!/bin/bash

# clean up any potential files in /tmp that may interfere with execution of this script
if [ -f "/tmp/"*LATEST* ]; then
rm /tmp/*LATEST*
fi

if [ -f "/tmp/"*.deb ]; then
rm /tmp/*.deb
fi

if [ -f "/tmp/"*.md5 ]; then
rm /tmp/*.md5
fi

if [ -f "/tmp/"*.nfo ]; then
rm /tmp/*.nfo
fi

# check what version we currently have installed
INSTALLED=`dpkg-query -W -f='${Version}' kodi-headless`

# set what to display if we are going to upgrade/downgrade main version
WARN_SET='/tmp/warn.nfo'
cat > $WARN_SET <<-WARNSIGN
##########################################################################
# You set the VERSION variable to a different main version no. than was  #
# locally installed, this script downgraded/upgraded kodi version to     #
# what you chose, make sure you have set the variable correctly and all  #
# your local kodi installs are at the same main version if you want to   #
# share libraries with them.                                             #
##########################################################################
WARNSIGN


# test if we are downgrading/upgrading depending on variable $VERSION
if [ -z "$VERSION" ]; then
FETCH_VER=${INSTALLED%.*}
else
FETCH_VER=$VERSION
fi

# get file with informaton on latest build of our chosen main version
wget -nd -nH -O /tmp/LATEST https://raw.githubusercontent.com/linuxserver/misc-files/master/kodi/LATEST$FETCH_VER
LATEST=$(cat /tmp/LATEST)
REMOTE_VERSION=$(sed 's/.*kodi-headless//' /tmp/LATEST | sed 's/amd64//g' | sed 's/_//g')

# decide if we need to update local version, if not exit from script gracefully
if [ "$REMOTE_VERSION" == "$INSTALLED" ]; then
echo "No Update Required"
exit 0;
fi

# fetch latest build and checksum it, if checksum fails then keep current version
wget -nd -nH -O /tmp/kodi-headless.md5 https://github.com/linuxserver/misc-files/blob/master/kodi/$LATEST.md5?raw=true
wget -nd -nH -O /tmp/kodi-headless.deb https://github.com/linuxserver/misc-files/blob/master/kodi/$LATEST.deb?raw=true

cd /tmp
CHECK_PASS=$(md5sum -c kodi-headless.md5)
if [ "$CHECK_PASS" = "kodi-headless.deb: OK" ]; then
echo "Checksum Passed"
else
echo "Checksum Failed, falling back to original version , try again by restarting the container"
exit 0;
fi

# if checksum passed, install latest build of our chosen main version
cd /
apt-get remove --purge -y kodi-headless
apt-get update -qq
gdebi -n /tmp/kodi-headless.deb
apt-get autoremove -y

# display warning about version change
if [ "$FETCH_VER" -ne "${INSTALLED%.*}" ]; then
echo >&2 "$(cat /tmp/warn.nfo)"
sleep 5s
fi
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
