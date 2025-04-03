ifeq ($(shell uname -s),Linux)
export LINUX = 1
endif

VERSION = 2.0

ifeq (LINUX, 1)

export TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = FridaCodeManager
export THEOS_PACKAGE_SCHEME = roothide
GO_EASY_ON_ME = 1

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
	@echo "Package: com.sparklechan.fridacodemanager" > control
	@echo "Name: FridaCodeManager" >> control
	@echo "Version: $(VERSION)" >> control
	@echo "Description: Full fledged Xcode-like IDE for iOS" >> control
	@echo "Depends: swift, clang-14, ldid, git" >> control
	@echo "Icon: https://raw.githubusercontent.com/fridakitten/FridaCodeManager/main/Blueprint/FridaCodeManager.app/AppIcon.png" >> control
	@echo "Conflicts: com.sparklechan.sparkkit" >> control
	@echo "Maintainer: FCCT" >> control
	@echo "Author: FCCT" >> control
	@echo "Section: Utilities" >> control
	@echo "Tag: role::hacker" >> control

include $(THEOS_MAKE_PATH)/application.mk

else # ifeq (LINUX, 0)

export ROOTDIR = $(shell pwd)
export SDK_PATH = $(ROOTDIR)/SDK
export OUTPUT_DIR = $(ROOTDIR)/Blueprint/FridaCodeManager.app
BUILD_PATH := .package/
SWIFT := $(shell find ./FCM/ -name '*.swift')

# Finding SHELL
ifeq ($(wildcard /bin/sh),)
ifeq ($(wildcard /var/jb/bin/sh),)
$(error "Neither /bin/sh nor /var/jb/bin/sh found.")
endif
SHELL := /var/jb/bin/sh
else
SHELL := /bin/sh
endif

export SHELL

PLF := -LEssentials/lib/prebuild -LEssentials/lib/build -lzip -lsean #-lserver -lcheck

# Targets
all: LF := -lroot -lfcm
all: ARCH := iphoneos-arm64
all: JB_PATH := /var/jb/
all: TARGET := jailbreak
all: greet compile_swift sign package_fs clean done

roothide: LF := -lroot -lfcm
roothide: ARCH := iphoneos-arm64e
roothide: JB_PATH := /
roothide: TARGET := jailbreak
roothide: greet compile_swift sign package_fs clean done

trollstore: LF := -lfcm
trollstore: TARGET := trollstore
trollstore: greet compile_swift sign makechain ipa clean done

# under construction!!!
stock: LF := -lfcm -ldycall
stock: TARGET := stock
stock: greet compile_swift makechain_jailed ipa clean done

get_sdk:
	@if [ ! -d SDK ]; then \
		mkdir -p tmp; \
		cd tmp; \
		unzip ../FCM/UI/TabBar/Settings/SDKHub/sdk/iOS15.6.zip; \
		mv iPhoneOS15.6.sdk ../SDK; \
		cd ../SDK; \
		mv System/Library/PrivateFrameworks/MobileContainerManager.framework System/Library/Frameworks/MobileContainerManager.framework; \
		rm -rf tmp; \
	fi
	@if [ ! -d $(OUTPUT_DIR)/include ]; then \
		cd $(OUTPUT_DIR); \
		git clone https://github.com/theos/headers; \
		mv headers include; \
	fi

greet:
	@echo "\nIts meant to be compiled on jailbroken iOS devices in terminal, compiling it using macos can cause certain anomalies with UI, etc\n "
	@#echo "PATH = $(PATH)"
	@if [ ! -d "Product" ]; then mkdir Product; fi

compile_swift: greet get_sdk
	@echo "\033[32mcompiling Essentials\033[0m"
	@$(MAKE) -C Essentials all
	@echo "\033[32mcompiling FridaCodeManager\033[0m"
	@output=$$(swiftc -wmo -warnings-as-errors -Xlinker -lswiftCore -Xcc -IEssentials/include -D$(TARGET) -sdk $(SDK_PATH) $(SWIFT) $(PLF) $(LF) -o "$(OUTPUT_DIR)/swifty" -parse-as-library -import-objc-header FCM/bridge.h -I$(OUTPUT_DIR)/include -framework MobileContainerManager -target arm64-apple-ios15.0 2>&1); \
	if [ $$? -ne 0 ]; then \
		echo "$$output" | grep -v "remark:"; \
		exit 1; \
	fi
	@$(MAKE) -C Essentials clean

sign: compile_swift
	@echo "\033[32msigning FridaCodeManager $(Version)\033[0m"
	@ldid -S./FCM/debug.xml $(OUTPUT_DIR)/swifty

package_fs: sign
	@echo "\033[32mpackaging FridaCodeManager\033[0m"
	@find . -type f -name ".DS_Store" -delete
	@-rm -rf $(BUILD_PATH)
	@mkdir $(BUILD_PATH)
	@mkdir -p $(BUILD_PATH)$(JB_PATH)Applications/FridaCodeManager.app
	@find . -type f -name ".DS_Store" -delete
	@cp -r Blueprint/FridaCodeManager.app/* $(BUILD_PATH)$(JB_PATH)Applications/FridaCodeManager.app
	@mkdir -p $(BUILD_PATH)DEBIAN
	@echo "Package: com.sparklechan.swifty\nName: FridaCodeManager\nVersion: $(VERSION)\nArchitecture: $(ARCH)\nDescription: Full fledged Xcode-like IDE for iOS\nDepends: swift, clang-14, ldid, git\nIcon: https://raw.githubusercontent.com/fridakitten/FridaCodeManager/main/Blueprint/FridaCodeManager.app/AppIcon.png\nConflicts: com.sparklechan.sparkkit\nMaintainer: FCCT\nAuthor: FCCT\nSection: Utilities\nTag: role::hacker" > $(BUILD_PATH)DEBIAN/control
	@-rm -rf Product/*
	@dpkg-deb -b $(BUILD_PATH) Product/FridaCodeManager.deb

makechain:
	@echo "\033[32mbuilding trollstore toolchain\033[0m"
	@cd Chainmaker && bash build.sh

makechain_jailed:
	@echo "\033[32mbuilding trollstore toolchain\033[0m"
	@cd Chainmaker && bash jailed.sh

ipa:
	@echo "\033[32mcreating .ipa\033[0m"
	@-rm -rf Product/*
	@mkdir -p Product/Payload/FridaCodeManager.app
	@cp -r ./Blueprint/FridaCodeManager.app/* ./Product/Payload/FridaCodeManager.app
	@mkdir Product/Payload/FridaCodeManager.app/toolchain
	@cp -r Chainmaker/.tmp/toolchain/* Product/Payload/FridaCodeManager.app/toolchain
	@cd Product && zip -rq FridaCodeManager.tipa ./Payload/*
	@rm -rf Product/Payload

#linkfix:
#	@install_name_tool -add_rpath /var/jb/usr/lib/llvm-16/lib $(OUTPUT_DIR)/swifty
#	@install_name_tool -add_rpath @loader_path $(OUTPUT_DIR)/swifty
#	@install_name_tool -add_rpath @loader_path/toolchain/lib $(OUTPUT_DIR)/swifty

clean: package_fs
	@rm -rf $(OUTPUT_DIR)/swifty $(OUTPUT_DIR)/*.dylib .package

extreme-clean:
	rm -rf SDK $(OUTPUT_DIR)/include

done: clean
	@echo "\033[32mall done! :)\033[0m"

endif