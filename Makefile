LIST=vkit
EARLY_DIRS=
LATE_DIRS=

ifeq ($(OS),Windows_NT)
    ifneq (,$(findstring cmd.exe,$(ComSpec)))
        VKIT_SHELL_TYPE:=cmd
    else
        VKIT_SHELL_TYPE:=bash
    endif
else
    VKIT_SHELL_TYPE:=bash
endif

ifeq ($(VKIT_SHELL_TYPE),cmd)
    VKIT_SETUP_SCRIPT:= vkit-setup.bat
else
    VKIT_ROOT_DIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    VKIT_ROOT_DIR:=$(patsubst %/,%,$(VKIT_ROOT_DIR))
    VKIT_ROOT_DIR!=[ -z "$(VKIT_ROOT_DIR)" ] && echo "." || echo "$(VKIT_ROOT_DIR)"
    VKIT_SETUP_SCRIPT := $(VKIT_ROOT_DIR)/vkit-setup.sh
    export VKIT_BUILD_CPU_CORE=$(shell echo '$(MAKEFLAGS)' | grep -o '\(^\| \)-j[0-9]\+' | sed -E 's/.*-j([0-9]+)/\1/')
endif

all:
	@$(VKIT_SETUP_SCRIPT) install
	@$(VKIT_SETUP_SCRIPT) deploy

import:
	@$(VKIT_SETUP_SCRIPT) import $(word 2, $(MAKECMDGOALS))

import_dev:
	@$(VKIT_SETUP_SCRIPT) import_dev

import_full:
	@$(VKIT_SETUP_SCRIPT) import_full

pull:
	@$(VKIT_SETUP_SCRIPT) pull

install:
	@$(VKIT_SETUP_SCRIPT) install

clean:
	@$(VKIT_SETUP_SCRIPT) clean

rclean:
	@$(VKIT_SETUP_SCRIPT) rclean

dclean:
	@$(VKIT_SETUP_SCRIPT) dclean

aclean:
	@$(VKIT_SETUP_SCRIPT) aclean

deploy:
	@$(VKIT_SETUP_SCRIPT) deploy

deploy_sdk:
	@$(VKIT_SETUP_SCRIPT) deploy_sdk

%:
	@:

.PHONY: all import import_dev import_full pull install clean rclean dclean aclean deploy deploy_sdk
