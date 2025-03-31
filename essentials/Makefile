include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libessentials

essentials_PUBLIC_HEADERS = $(shell find include -type f -name "*.h")
essentials_INSTALL_PATH = /usr/local/lib

include $(THEOS_MAKE_PATH)/library.mk
SUBPROJECTS += libfcm
SUBPROJECTS += libsean
include $(THEOS_MAKE_PATH)/aggregate.mk
