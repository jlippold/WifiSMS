CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-gcc-4.2.1
CPP=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.2.1

SDKVER=3.0
SDK=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVER).sdk

LD=$(CC)
LDFLAGS += -lobjc -dynamiclib -bind_at_load
LDFLAGS += -framework CoreFoundation 
LDFLAGS += -framework Foundation 
LDFLAGS += -framework UIKit 
LDFLAGS += -framework CoreGraphics
LDFLAGS += -framework CoreTelephony
LDFLAGS += -framework SystemConfiguration

LDFLAGS += -L"$(SDK)/usr/lib"
LDFLAGS += -F"$(SDK)/System/Library/Frameworks"
LDFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"

LDFLAGS += -L"$(SDK)/usr/lib"
LDFLAGS += -F"$(SDK)/System/Library/Frameworks" 
LDFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"

CFLAGS += -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/gcc/arm-apple-darwin9/4.0.1/include/"
CFLAGS += -I"$(SDK)/usr/include"
CFLAGS += -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/include/"
CFLAGS += -I"/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$(SDKVER).sdk/usr/include"
CFLAGS += -DDEBUG -std=c99
CFLAGS += -Diphoneos_version_min=2.0
CFLAGS += -F"$(SDK)/System/Library/Frameworks"
CFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks" 

//CFLAGS += fconstant-cfstrings -std=gnu99 -Wall -O2 -I/var/include -I..
VERSION=1.0  
 

CPPFLAGS=$CFLAGS

all:    Toggle.dylib

Toggle.dylib:  main.o 
	$(LD) $(LDFLAGS) -v -o $@ $^

%.o: %.m
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@
	   
%.o: %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
		rm -f *.o edge