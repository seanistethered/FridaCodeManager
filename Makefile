export TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = FridaCodeManager
export THEOS_PACKAGE_SCHEME = roothide
GO_EASY_ON_ME = 1

VERSION = 2.0

export ARCHS = arm64
export THEOS_LINKAGE_TYPE = static
TARGET_CODESIGN_FLAGS = -SFCM/debug.xml

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += Essentials
include $(THEOS_MAKE_PATH)/aggregate.mk

APPLICATION_NAME = FridaCodeManager

FridaCodeManager_FILES = $(shell find ./FCM/ -name '*.swift')

FridaCodeManager_SWIFT_BRIDGING_HEADER = FCM/bridge.h
FridaCodeManager_FRAMEWORKS = UIKit CoreGraphics CoreFoundation
FridaCodeManager_PRIVATE_FRAMEWORKS = MobileContainerManager

FridaCodeManager_LDFLAGS = -L$(THEOS_OBJ_DIR) -LEssentials/prebuild 
FridaCodeManager_LIBRARIES = sean fcm zip root swiftCore

FridaCodeManager_SWIFTFLAGS = -Xcc -IEssentials/include -parse-as-library -Djailbreak

FridaCodeManager_BUNDLE_RESOURCE_DIRS = Blueprint/FridaCodeManager.app

before-stage::
	@if [ ! -d $(FridaCodeManager_BUNDLE_RESOURCE_DIRS)/include ]; then \
		cd $(FridaCodeManager_BUNDLE_RESOURCE_DIRS); \
		git clone --depth=1 https://github.com/theos/headers; \
		mv headers include; \
	fi

before-package::
	@echo "Package: com.sparklechan.fridacodemanager\nName: FridaCodeManager\nVersion: $(VERSION)\nDescription: Full fledged Xcode-like IDE for iOS\nDepends: swift, clang-14, ldid, git\nIcon: https://raw.githubusercontent.com/fridakitten/FridaCodeManager/main/Blueprint/FridaCodeManager.app/AppIcon.png\nConflicts: com.sparklechan.sparkkit\nMaintainer: FCCT\nAuthor: FCCT\nSection: Utilities\nTag: role::hacker" > control

include $(THEOS_MAKE_PATH)/application.mk
