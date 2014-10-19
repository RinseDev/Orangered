THEOS_PACKAGE_DIR_NAME = debs
TARGET = :clang:latest
ARCHS = armv7 armv7s arm64

GO_EASY_ON_ME = 1
# treats warnings as warnings due to External library issues

include theos/makefiles/common.mk

# rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

TWEAK_NAME = Orangered
Orangered_FILES = Orangered.xm ORProviders.xm $(wildcard External/*.m)
Orangered_FRAMEWORKS = AudioToolbox CFNetwork CoreLocation Security StoreKit UIKit QuartzCore CoreGraphics SystemConfiguration Security MobileCoreServices
Orangered_PRIVATE_FRAMEWORKS = BulletinBoard ToneLibrary PersistentConnection Preferences
Orangered_LIBRARIES += z
Orangered_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += ORPrefs ORListener
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"

