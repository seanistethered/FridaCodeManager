export TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = FridaCodeManager

export ARCHS = arm64
export USE_DEPS = 1

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += essentials
include $(THEOS_MAKE_PATH)/aggregate.mk

APPLICATION_NAME = FridaCodeManager

FridaCodeManager_FILES = $(shell find ./FCM/ -name '*.swift')
FridaCodeManager_FRAMEWORKS = UIKit CoreGraphics CoreFoundation
FridaCodeManager_PRIVATE_FRAMEWORKS = MobileContainerManager
FridaCodeManager_LDFLAGS = -L$(THEOS_OBJ_DIR) -Lessentials/prebuild 
FridaCodeManager_LIBRARIES = sean fcm essentials zip root

FridaCodeManager_SWIFTFLAGS = -Xcc -Iessentials/include -parse-as-library -import-objc-header FCM/bridge.h -Djailbreak

before-all::
	echo $(THEOS_OBJ_DIR)

include $(THEOS_MAKE_PATH)/application.mk
