THEOS_PACKAGE_DIR_NAME = debs
TARGET = iphone:clang:latest:7.0
ARCHS = armv7 arm64
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

TWEAK_NAME = Orangered
Orangered_FILES = Orangered.xm ORProviders.xm External/FDKeychain/FDKeychain.m $(wildcard External/RedditKit/*.m) $(wildcard External/RedditKit/Mantle/*.m) $(wildcard External/RedditKit/AFNetworking/*.m)
Orangered_FRAMEWORKS = AudioToolbox CFNetwork CoreLocation Security StoreKit UIKit QuartzCore CoreGraphics SystemConfiguration Security MobileCoreServices
Orangered_PRIVATE_FRAMEWORKS = BulletinBoard ToneLibrary PersistentConnection Preferences
Orangered_LIBRARIES += z
Orangered_CFLAGS = -fobjc-arc
Orangered_CFLAGS += -I External/FDKeychain
Orangered_CFLAGS += -I External/RedditKit
Orangered_CFLAGS += -I External/RedditKit/AFNetworking
Orangered_CFLAGS += -I External/RedditKit/Mantle

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += ORPrefs ORListener
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"
