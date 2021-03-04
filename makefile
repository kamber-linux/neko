include config.mk

# Mainly for non-GNU make
SHELL = /bin/sh

default: help

install:
	@echo "\033[1mInstalling binary...\033[0m"
	mkdir -p ${BINPREFIX}
	cp -r neko ${BINPREFIX}
	chmod 755 ${BINPREFIX}/neko
	@echo "\033[1mInstalling man page...\033[0m"
	mkdir -p ${MANPREFIX}
	cp -r neko.1 ${MANPREFIX}
	chmod 644 ${MANPREFIX}/neko.1

uninstall:
	@echo "\033[1mRemoving binary...\033[0m"
	rm -rf ${BINPREFIX}/neko
	@echo "\033[1mRemoving man page...\033[0m"
	rm -rf ${MANPREFIX}/neko.1

help:
	@echo "Please specify \033[1minstall\033[0m or \033[1muninstall\033[0m option"

.PHONY: default install uninstall help
