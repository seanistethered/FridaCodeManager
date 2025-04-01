include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libsean

libsean_INSTALL = 0

libsean_FILES = $(shell find . -type f -name "*.c") $(shell find . -type f -name "*.m")
libsean_CFLAGS = -fobjc-arc -ISOC -ICompiler

include $(THEOS_MAKE_PATH)/library.mk
