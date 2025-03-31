include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libfcm

libfcm_FILES = $(wildcard *.m) $(wildcard *.c)
libfcm_CFLAGS = -fobjc-arc
libfcm_INSTALL_PATH = /usr/local/lib
libfcm_PRIVATE_FRAMEWORKS = MobileContainerManager
libfcm_DYNAMIC_LIBRARY = 0

include $(THEOS_MAKE_PATH)/library.mk
