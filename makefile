include config.mk

# Mainly for non-GNU make
SHELL = /bin/sh

default: help

install:
	@echo "\033[1mInstalling binary..."
	mkdir -p ${BINDIR}
	cp -r neko ${BINDIR}
	chmod 755 ${BINDIR}/neko
	@echo "\033[1mInstalling man page..."
	mkdir -p ${MANDIR}
	cp -r neko.1 ${MANDIR}
	chmod 644 ${MANDIR}/neko.1

uninstall:
	rm -rf ${BINDIR}/neko
	rm -rf ${MANDIR}/neko.1

help:
	@echo "Please specify \033[1minstall\033[0m or \033[1muninstall\033[0m option"

.PHONY: default install uninstall help
