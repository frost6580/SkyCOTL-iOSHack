ARCHS = arm64 #arm64e
THEOS_DEVICE_IP = 192.168.11.4
THEOS=/home/frost6580/theos
DEBUG = 0
FINALPACKAGE = 1
INSTALL_TARGET_PROCESSES = Sky

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ImGuiMod

$(TWEAK_NAME)_LIBRARIES += substrate
$(TWEAK_NAME)_FILES = ImGuiDrawView.mm $(wildcard ImGui/*.cpp) $(wildcard ImGui/*.mm)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = Foundation UIKit Metal MetalKit #QuartzCore
$(TWEAK_NAME)_CCFLAGS = -std=c++11 -fno-rtti -DNDEBUG -Wno-unused-private-field -Wno-unused-variable #-O3 

#GO_EASY_ON_ME = 1

include $(THEOS_MAKE_PATH)/tweak.mk


