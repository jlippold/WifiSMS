#!/bin/bash

VERSION="1.0.9"

cd `dirname $0`
cd ..

find . -name .DS_Store -ls -exec rm {} \;

rm -r temp
mkdir -p temp/var/mobile/Library/SBSettings/
cp -r wifiSMS/build/Release-iphoneos/WifiSMS/ temp/var/mobile/Library/WifiSMS/
cp -r Build/cydia/WifiSMS/DEBIAN/ temp/DEBIAN/
sed -e "s/^Version: VERSION$/Version: ${VERSION}/" Build/cydia/WifiSMS/DEBIAN/control > temp/DEBIAN/control
cp -r SBS-Toggle/Commands/ temp/var/mobile/Library/SBSettings/Commands/
cp -r SBS-Toggle/Themes/ temp/var/mobile/Library/SBSettings/Themes/
cp -r SBS-Toggle/Toggles/ temp/var/mobile/Library/SBSettings/Toggles/
dpkg-deb -b temp Build/deb/WifiSMS-${VERSION}.deb

rm -r temp/var/mobile/Library/SBSettings/
rm -r temp/DEBIAN/
cp -r Build/cydia/WifiSMS-NoSBS/DEBIAN/ temp/DEBIAN/
sed -e "s/^Version: VERSION$/Version: ${VERSION}/" Build/cydia/WifiSMS-NoSBS/DEBIAN/control > temp/DEBIAN/control
dpkg-deb -b temp Build/deb/WifiSMS-NOSBS-${VERSION}.deb