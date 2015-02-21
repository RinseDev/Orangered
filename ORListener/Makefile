TARGET = iphone:clang:latest:7.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

TWEAK_NAME = ORListener
ORListener_FILES = ORListener.xm
ORListener_FRAMEWORKS = Foundation UIKit
ORListener_LDFLAGS = -lactivator -L../theos/lib

include $(THEOS_MAKE_PATH)/tweak.mk
