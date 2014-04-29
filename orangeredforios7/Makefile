include theos/makefiles/common.mk

BUNDLE_NAME = OrangeredForiOS7
OrangeredForiOS7_FILES = OrangeredForiOS7.mm
OrangeredForiOS7_INSTALL_PATH = /Library/PreferenceBundles
OrangeredForiOS7_FRAMEWORKS = UIKit
OrangeredForiOS7_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/OrangeredForiOS7.plist$(ECHO_END)
