TARGET = iphone:clang:12.0:12.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SilentPillHUD
SilentPillHUD_FILES = Tweak.xm
SilentPillHUD_FRAMEWORKS = UIKit QuartzCore CoreGraphics
SilentPillHUD_CFLAGS = -fobjc-arc
SilentPillHUD_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/tweak.mk
