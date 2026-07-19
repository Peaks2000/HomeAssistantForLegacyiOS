TARGET ?= iphone:clang:9.3:4.0
ARCHS ?= armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HALegacy

HALegacy_FILES = main.m HAAppDelegate.m HAAuthClient.m HACameraViewController.m \
	HADevicePickerViewController.m HAEntityDetailViewController.m HAEntityListViewController.m \
	HAHomeManager.m HAHomesViewController.m \
	HASettingsViewController.m HAURLCompatibility.m HAVerificationViewController.m \
	HAWatchManager.m HAWatchServiceRequest.m
HALegacy_FRAMEWORKS = UIKit Foundation
HALegacy_WEAK_FRAMEWORKS = WatchConnectivity
HALegacy_CFLAGS = -fno-objc-arc -Wall -Wextra -Wno-deprecated-declarations -Wno-objc-method-access
HALegacy_INSTALL_PATH = /Applications
HALegacy_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache"
