# About
`neko` is a WIP package manager written in POSIX shell script and (mostly) POSIX utilities inspired by VOID's `xbps-src` bash script package builder and Gentoo's portage source-based package manager. The command usage and name is inspired by Ataraxia's package manager of the same name (it means "cat" in Japanese 猫). The end goal is to write a package manager using POSIX shell and standard POSIX utilities found in userspaces such as suckless's sbase, GNU's Core Utils, among others (e.g. `id`, `sed`, `cut`, etc). The vision is to make it easy to write templates for like in `xbps-src` and have source based installations like portage from Gentoo.
# Installation
The `makefile` is really more for testing as this is not complete / able to be used, yet. With that in mind, the `install` rule will install the script and man page - `make install`.
# Usage
Start with copying the included templates to the directory where builds are done - `./neko init`. Then, try building one of the packages - `./neko pkg <pkg-name>`.
# Packages
Very similarly to VOID's package builder, `xbps-src`, every package has it's own folder in `srcpkgs` defined by its `template` file, which gives information on how to build, where to get the source, et cetera. For an example, `neko pkg st` will build based off of `srcpkgs/st/template`:
```
pkgname="st"
version="0.8.4"
revision="1"
distfiles="https://dl.suckless.org/st/st-${version}.tar.gz"
build_style="makefile"
license="MIT"
license_file="LICENSE"
```
## Steps
Every package will go through these steps:
```
neko_prepare - prepare the enviornment for building the package and get the info from the template
neko_fetch   - get the source (currently using wget)
neko_extract - extract the source (if not using a git build)
neko_patch   - apply patches in srcpkgs/<pkgname>/patches
neko_build   - build the package
```
Those are the steps for `neko pkg <pkgname>`. If installing via `neko em <pkgname>`, the process will also invoke `neko_install`, which installs the package.
## Making a package
A quick way to make a new package is `./neko new <pkg-name>` for testing.
To make a new package for pull request, make a directory in `srcpkgs` with the `<pkgname>` - i.e. `mkdir -p srcpkgs/<pkgname>`. Then, write a file `srcpkgs/<pkgname>/template` with the following content:
```
pkgname            - the name of the package
version            - the version of the package (if applicable / not a git build)
revision           - changes / updates to the template without changing the version, always starts at 1
distfiles / giturl - the link to the source archive or the link to the git repo
build_style        - the way to build the package (see Build Styles section)
license            - the license that the software is released under
```
### Build Styles
Projects very often contain similar steps to build, so `build_style` is meant to simplify the process. At the moment, there are three Build Styles available that do the following at the `neko_build` phase:
```
makefile:
	make ${make_args}
configure:
	./configure ${configure_args}
	make ${make_args}
meson:
	meson build
	ninja -C build
```
These steps can be over-written in the template, as well, if the upstream package has different instructions. For example, the `bearssl` and `mksh` templates:
```
pkgname="bearssl"
version="0.6"
revision="1"
distfiles="https://bearssl.org/bearssl-${version}.tar.gz"
build_style="makefile"

neko_install()
{
	neko_pkg install bin build/brssl
	neko_pkg install lib libbearssl.so
	neko_pkg install lib libbearssl.a
}

neko_uninstall()
{
	neko_pkg uninstall bin brssl
	neko_pkg uninstall lib libbearssl.so
	neko_pkg uninstall lib libbearssl.a
}

neko_subpkg()
{
	pkgname="bearssl-devel"
	neko_install()
	{
		neko_pkg install inc inc/*
	}
	neko_uninstall()
	{
		for file in bearssl.h bearssl_aead.h bearssl_block.h bearssl_ec.h\
			bearssl_hash.h bearssl_hmac.h bearssl_kdf.h bearssl_pem.h bearssl_prf.h\
			bearssl_rand.h bearssl_rsa.h bearssl_ssl.h bearssl_x509.h
		do
			neko_pkg uninstall inc "${file}"
		done
	}
}
```
```
pkgname="mksh"
version="R59c"
revision="1"
distfiles="http://www.mirbsd.org/MirOS/dist/mir/mksh/mksh-${version}.tgz"
wrksrc="mksh"
license="custom"
license_file="${files_dir}/TaC-mksh.txt"

neko_build()
{
	sh ./Build.sh -r
}

neko_install()
{
	neko_pkg install bin mksh
	neko_pkg install man mksh.1
	mv dot.mkshrc .mkshrc
	neko_pkg install conf .mkshrc /skel
}

neko_uninstall()
{
	neko_pkg uninstall bin mksh
	neko_pkg uninstall man mksh.1
	neko_pkg uninstall conf skel/.mkshrc
}
```
These build styles will try and use `bmake` and `tcc` by default. If GNU `make` is needed, there are `gnu-configure` and `gnu-makefile` build styles. If `gcc` is needed, one can add a `TCC="false" # reason (if applicable)` in the template. For example, the `musl` template:
```
pkgname="musl"
version="1.1.24"
revision="1"
distfiles="https://musl-libc.org/releases/musl-${version}.tar.gz"
build_style="gnu-configure"
TCC="false" # ./src/internal/dynlink.h:105: error: invalid type
```
The `neko_subpkg` command is currently a work in progress. It would be nice to be able to install `-devel` packages with neko that way one doesn't need them on the host system.
# Contributing
For contributing to the shell script, shellcheck is used to ensure portability. Please try and use only POSIX utilities (at the moment `wget` and `tar` are the only non-standard utilities as far as I know). When making a pull request, please make a branch with a relavent name and request to merge to the `develop` branch, unless you're making a pull request for a new package.
## Packages
**PACKAGES MUST:**
* Be able to be built against musl libc libraries
* Be able to be built against bearssl libraries

I strongly push for packages to:
* Adhere to XDG specifications (e.g. not filling up your `$HOME` folder)
* Try and be compiled with TCC (if possible) to save time on compiling

As for how to contribute, it's similar to VOID.
I love the way VOID handles pull requests for new packages, so we'll follow. When pull requesting for packages, request to merge with the master branch.
### New packages
For a new package, there should only be one commit per package with the commit message: `New package: <pkgname>-<version>`. If you're requesting a git build, please attach `-git` to the end of the package name (`srcpkgs/<pkgname>-git/template` will have `pkgname=<pkgname>-git`) with the commit message: `New package: <pkgname>-git`.
### Updating packages
For updating a package, please have the commit message be: `<pkgname>: update to <version>`.
### Patches
This is how I would recommend doing patches. Make two directories, `a` and `b`, then copy the file / files you want to patch to both. Edit the file / files in `b`. Then, `diff -Naur a/<file> b/<file> > <patch-name>.patch`. Then make a directory in `srcpkgs/<pkgname>` called `patches` and put it in there.
# TODO
* Add more build styles / packages
* Find a POSIX way to replace the `wget` solution for `neko_fetch`
