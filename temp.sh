#!/bin/bash

ssh root@192.168.1.140
send "alpine\r"
interact
EOD
rm -rf /private/var/mobile/Library/WifiSMS/
mkdir /private/var/mobile/Library/WifiSMS/
exit

scp -r /Users/TreAsoN/WifiSMS/wifiSMS/build/Release-iphoneos/WifiSMS/ root@192.168.1.140:/private/var/mobile/Library/
alpine

ssh root@192.168.1.140 
alpine
chown -R mobile:mobile /private/var/mobile/Library/WifiSMS
chmod 0755 /private/var/mobile/Library/WifiSMS/WifiSMS
exit