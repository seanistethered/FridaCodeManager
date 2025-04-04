# Makefile
#
# Compile all FridaCodeManager essentials
# :3
#

ifeq ($(LINUX), 1)

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += libfcm
SUBPROJECTS += libsean
include $(THEOS_MAKE_PATH)/aggregate.mk

else # ifeq ($(LINUX), 0)

export SDKROOT := sdk

export CC := clang
export CF := -target arm64-apple-ios15 -arch arm64 -I$(ROOTDIR)/include

export COBJ_DIR := tmp/out/c
export MOBJ_DIR := tmp/out/m

# fishy patch
export uuid := uuid

all: libfcm-compile libdycall-compile libsean-compile #libcheck-compile

prepare:
	@rm -rf lib/build
	@mkdir -p lib/build

%-compile: prepare
	@$(MAKE) -C $* all || $(MAKE) -C $* clean
	@cp $*/tmp/lib/$*.a lib/build/$*.a
	@$(MAKE) -C $* clean

clean:
	@rm -rf lib/build

endif