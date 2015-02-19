TARGET = iphone:clang:latest:7.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

BUNDLE_NAME = ORPrefs
ORPrefs_OBJC_FILES = ORPrefs.xm
ORPrefs_INSTALL_PATH = /Library/PreferenceBundles
ORPrefs_FRAMEWORKS = Foundation UIKit Twitter
ORPrefs_PRIVATE_FRAMEWORKS = Preferences MobileCoreServices MobileInstallation
ORPrefs_LDFLAGS = -lapplist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ORPrefs.plist$(ECHO_END)
