.POSIX:

# Mainly for non-GNU make
SHELL = /bin/sh

# Installation paths
PREFIX       = /usr/local
BINPREFIX    = ${PREFIX}/bin
MANPREFIX    = ${PREFIX}/share/man/man1
BASEPREFIX   = ${PREFIX}/share/neko
MASTERPREFIX = ${BASEPREFIX}/master

BINDIR    = ${DESTDIR}${BINPREFIX}
MANDIR    = ${DESTDIR}${MANPREFIX}
BASEDIR   = ${DESTDIR}${BASEPREFIX}
MASTERDIR = ${DESTDIR}${MASTERPREFIX}

default: help

install:
	@echo "\033[1mInstalling binary...\033[0m"
	mkdir -p ${BINDIR}
	cp -r neko ${BINDIR}
	chmod 755 ${BINDIR}/neko
	@echo "\033[1mInstalling man page...\033[0m"
	mkdir -p ${MANDIR}
	cp -r neko.1 ${MANDIR}
	chmod 644 ${MANDIR}/neko.1
	@echo "\033[1mInstalling base files...\033[0m"
	mkdir -p ${BASEDIR}
	cp -r srcpkgs ${BASEDIR}
	cp -r licenses ${BASEDIR}
	mkdir -p ${MASTERDIR}

uninstall:
	@echo "\033[1mUninstalling binary...\033[0m"
	rm -rf ${BINDIR}/neko
	@echo "\033[1mUninstalling man page...\033[0m"
	rm -rf ${MANDIR}/neko.1
	@echo "\033[1mUninstalling base files...\033[0m"
	rm -rf ${BASEDIR}

help:
	@echo "Please specify \033[1minstall\033[0m or \033[1muninstall\033[0m option"

.PHONY: default install uninstall help
