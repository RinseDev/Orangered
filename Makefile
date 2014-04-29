<<<<<<< HEAD
THEOS_PACKAGE_DIR_NAME = debs
TARGET =: clang
ARCHS = armv7 armv7s arm64
include theos/makefiles/common.mk

TWEAK_NAME = Orangered
Orangered_FILES = Orangered.xm ORProvider.xm $(wildcard *.m)
Orangered_FRAMEWORKS = Foundation UIKit AudioToolbox
Orangered_PRIVATE_FRAMEWORKS = AppSupport BulletinBoard
Orangered_CFLAGS = -fobjc-arc
Orangered_LDFLAGS = -Wlactivator -Ltheos/lib

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += ORPreferences
SUBPROJECTS += ORListener
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-after-install::
	install.exec "killall -9 backboardd"
=======
ARCHS = armv7 armv7s arm64
TARGET=iphone:clang:latest
include theos/makefiles/common.mk
GO_EASY_ON_ME = 1

TWEAK_NAME = OrangeredForiOS7
OrangeredForiOS7_FILES = Tweak.xm $(wildcard *.m) Listener.x
OrangeredForiOS7_FRAMEWORKS = AudioToolbox CFNetwork CoreLocation Security StoreKit UIKit QuartzCore CoreGraphics SystemConfiguration Security MobileCoreServices
OrangeredForiOS7_PRIVATE_FRAMEWORKS = BulletinBoard
OrangeredForiOS7_CFLAGS = -fobjc-arc
OrangeredForiOS7_LDFLAGS = -L/usr/lib/ -lactivator
OrangeredForiOS7_LIBRARIES += z

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += orangeredforios7
include $(THEOS_MAKE_PATH)/aggregate.mk
>>>>>>> rewrite
