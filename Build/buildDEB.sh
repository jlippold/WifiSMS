#!/bin/bash

cd ~/WifiSMS/

find . -name .DS_Store -ls -exec rm {} \;

rm -r ~/WifiSMS/Build/cydia/WifiSMS/private/var/mobile/Library/WifiSMS/
rm -r ~/WifiSMS/Build/cydia/WifiSMS-NoSBS/private/var/mobile/Library/WifiSMS/

cp -r ~/WifiSMS/wifiSMS/build/Release-iphoneos/WifiSMS.app/ ~/WifiSMS/Build/cydia/WifiSMS/private/var/mobile/Library/WifiSMS/
cp -r ~/WifiSMS/wifiSMS/build/Release-iphoneos/WifiSMS.app/ ~/WifiSMS/Build/cydia/WifiSMS-NoSBS/private/var/mobile/Library/WifiSMS/

cd ~/WifiSMS/Build/cydia/

dpkg-deb -b WifiSMS ~/WifiSMS/Build/deb/WifiSMS-1.0.4.deb

dpkg-deb -b WifiSMS-NoSBS ~/WifiSMS/Build/deb/WifiSMS-NOSBS-1.0.4.deb