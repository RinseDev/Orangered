THEOS_PACKAGE_DIR_NAME = debs
TARGET = :clang:latest
ARCHS = armv7 arm64

GO_EASY_ON_ME = 1
# treats warnings as warnings due to External library issues

include theos/makefiles/common.mk

TWEAK_NAME = Orangered
Orangered_FILES = Orangered.xm ORProviders.xm External/FDKeychain/FDKeychain.m $(wildcard External/RedditKit/External/AFNetworking/*.m) $(wildcard External/RedditKit/External/Mantle/*.m) $(wildcard External/RedditKit/Classes/Categories/*.m) $(wildcard External/RedditKit/Classes/Model/*.m) $(wildcard External/RedditKit/Classes/Networking/*.m)
Orangered_FRAMEWORKS = AudioToolbox CFNetwork CoreLocation Security StoreKit UIKit QuartzCore CoreGraphics SystemConfiguration Security MobileCoreServices
Orangered_PRIVATE_FRAMEWORKS = BulletinBoard ToneLibrary PersistentConnection Preferences
Orangered_LIBRARIES += z
Orangered_CFLAGS = -fobjc-arc 
Orangered_CFLAGS += -I External/FDKeychain External/RedditKit/Classes External/RedditKit/Classes/Categories External/RedditKit/Classes/Model External/RedditKit/Classes/Networking External/RedditKit/External/AFNetworking

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += ORPrefs ORListener
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"
