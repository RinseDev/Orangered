TARGET=:clang
ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = ORListener
ORListener_OBJC_FILES = ORListener.xm ../ORLogger.m
ORListener_FRAMEWORKS = Foundation UIKit
ORListener_LDFLAGS = -lactivator -L../theos/lib

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk