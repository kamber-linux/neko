.POSIX:

SHELL = /bin/sh

EXEC = neko

PREFIX     = /usr/local
BINPREFIX  = $(PREFIX)/bin
MAN1PREFIX = $(PREFIX)/share/man/man1

BASE_DIR     = $(PREFIX)/share/neko
PKGS_DIR     = $(BASE_DIR)/srcpkgs
DB_DIR       = /var/db/neko
MASTER_DIR   = $(BASE_DIR)/master
LICENSES_DIR = $(MASTER_DIR)/licenses
SRC_DIR      = $(MASTER_DIR)/src
ROOT_DIR     = $(MASTER_DIR)/root

default: help

install:
	@echo "Installing binary..."
	mkdir -p $(DESTDIR)$(BINPREFIX)
	cp $(EXEC) $(DESTDIR)$(BINPREFIX)
	chmod 755 $(DESTDIR)$(BINPREFIX)/$(EXEC)
	@echo "Installing man page..."
	mkdir -p $(DESTDIR)$(MAN1PREFIX)
	cp $(EXEC).1 $(DESTDIR)$(MAN1PREFIX)
	chmod 644 $(DESTDIR)$(MAN1PREFIX)/$(EXEC).1
	@echo "Making base directories..."
	mkdir -p $(DESTDIR)$(BASE_DIR)
	mkdir -p $(DESTDIR)$(PKGS_DIR)
	mkdir -p $(DESTDIR)$(DB_DIR)
	mkdir -p $(DESTDIR)$(MASTER_DIR)
	mkdir -p $(DESTDIR)$(LICENSES_DIR)
	mkdir -p $(DESTDIR)$(SRC_DIR)
	mkdir -p $(DESTDIR)$(ROOT_DIR)
	@echo "Installing base files..."
	cp -R srcpkgs $(DESTDIR)$(PKGS_DIR)
	cp -R master/licenses $(DESTDIR)$(LICENSES_DIR)

uninstall:
	@echo "Removing binary..."
	rm -f $(DESTDIR)$(BINPREFIX)/$(EXEC)
	@echo "Removing man page..."
	rm -f $(DESTDIR)$(MAN1PREFIX)/$(EXEC).1
	@echo "Removing base directories and files..."
	rm -rf $(DESTDIR)$(BASE_DIR)
	rm -rf $(DESTDIR)$(DB_DIR)

help:
	@echo "$(EXEC) is a shell script - no need to build"
	@echo "Run make install"

.PHONY: default install uninstall help
