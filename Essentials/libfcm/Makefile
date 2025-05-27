# Makefile
#
# libfcm
# Meow :3
# Created by SeanIsNotAConstant on October the 12th 2024
#

ifeq ($(LINUX), 1)

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libfcm
libfcm_INSTALL = 0

libfcm_FILES = $(wildcard *.m) $(wildcard *.c)
libfcm_CFLAGS = -fobjc-arc
libfcm_PRIVATE_FRAMEWORKS = MobileContainerManager

include $(THEOS_MAKE_PATH)/library.mk

else # ifeq ($(LINUX), 0)

# finding all C and Objective-C files
CFILES := $(shell find . -name "*.c")
MFILES := $(shell find . -name '*.m')

# listing all compiled objects
OBJS := $(patsubst %.c,$(COBJ_DIR)/%.o,$(CFILES)) $(patsubst %.m,$(MOBJ_DIR)/%.o,$(MFILES))

# compiling them to libsean16

all: setup bind

$(COBJ_DIR)/%.o: %.c setup
	@mkdir -p $(dir $@)
	@$(CC) -isysroot $(SDKROOT) $(CF) -ISOC -c $< -o $@

$(MOBJ_DIR)/%.o: %.m setup
	@mkdir -p $(dir $@)
	@$(CC) -isysroot $(SDKROOT) $(CF) -ISOC -c $< -o $@

setup:
	@rm -rf tmp
	@mkdir -p $(COBJ_DIR) $(MOBJ_DIR)
	@mkdir -p tmp/lib

bind: setup $(OBJS)
	@ar rcs tmp/lib/libfcm.a $(OBJS)

clean:
	@rm -rf tmp

endif