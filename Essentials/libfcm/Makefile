include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libfcm
libfcm_INSTALL = 0

libfcm_FILES = $(wildcard *.m) $(wildcard *.c)
libfcm_CFLAGS = -fobjc-arc
libfcm_PRIVATE_FRAMEWORKS = MobileContainerManager

include $(THEOS_MAKE_PATH)/library.mk
