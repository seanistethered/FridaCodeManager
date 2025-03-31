include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libsean

libsean_FILES = $(shell find . -type f -name "*.c") $(shell find . -type f -name "*.m")
libsean_CFLAGS = -fobjc-arc -ISOC -ICompiler
libsean_INSTALL_PATH = /usr/local/lib
libsean_DYNAMIC_LIBRARY = 0

include $(THEOS_MAKE_PATH)/library.mk
