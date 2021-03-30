# About
`neko` is a WIP package manager written in POSIX shell script inspired by VOID's `xbps-src` bash script and Gentoo's portage source-based package manager. The command usage and name is inspired by Ataraxia's package manager of the same name (it means "cat" in Japanese 猫). The end goal is to write a package manager using POSIX shell and standard POSIX utilities found in userspaces such as suckless's sbase, GNU's Core Utils, among others (e.g. `id`, `sed`, `cut`, etc). This vision is to make it easy to write templates for like in `xbps-src` and source based installations like portage from Gentoo.
# Installation
The `makefile` is really more for testing as this is not complete / able to be used, yet. With that in mind, the `install` rule will install the script and man page - `make install`.
# Usage
To build one of the `srcpkgs` locally - `neko pkg <pkgname>`. e.g. - `neko pkg bearssl`
# Packages
Very similarly to VOID's package builder, `xbps-src`, every package has it's own folder in `srcpkgs` defined by its `template` file, which gives information on how to build, where to get the source, et cetera. For an example, `neko pkg st` will build based off of `srcpkgs/st/template`:
```
pkgname=st
version=0.8.4
distfiles="https://dl.suckless.org/${pkgname}/${pkgname}-${version}.tar.gz"
checksum=d42d3ceceb4d6a65e32e90a5336e3d446db612c3fbd9ebc1780bc6c9a03346a6
build_style=makefile
```
## Steps
Every package will go through these steps:
```
neko_prepare - prepare the enviornment for building the package and get the info from the template
neko_fetch   - get the source (currently using wget)
neko_check   - check the checksum against the one in the template (if not using a git build)
neko_extract - extract the source (if not using a git build)
neko_patch   - apply patches in srcpkgs/<pkgname>/patches
neko_build   - build the package
```
Those are the steps for `neko pkg <pkgname>`. If installing via `neko em <pkgname>`, the process will also invoke `neko_install`, which installs the package.
## Making a package
To make a new package, make a directory in `srcpkgs` with the `<pkgname>` - i.e. `mkdir -p srcpkgs/<pkgname>`. Then, write a file `srcpkgs/<pkgname>/template` with the following content:
```
pkgname            - the name of the package
version            - the version of the package (if applicable / not a git build)
distfiles / giturl - the link to the source archive or the link to the git repo
checksum           - the checksum of the source archive (if not using a git build) - `sha256sum <source-archive>`
build_style        - the way to build the package (see Build Styles section)
```
### Build Styles
Projects very often contain similar steps to build, so `build_style` is meant to simplify the process. At the moment, there are three Build Styles available that do the following at the `neko_build` phase:
```
makefile:
	make
configure:
	./configure
	make
meson:
	meson build
	ninja -C build
```
These steps can be over-written in the template, as well, if the upstream package has different instructions. For example, the `bearssl` template:
```
pkgname=bearssl
version=0.6
distfiles="https://bearssl.org/${pkgname}-${version}.tar.gz"
checksum=6705bba1714961b41a728dfc5debbe348d2966c117649392f8c8139efc83ff14
build_style=makefile

neko_install()
{
	mkdir -p ${DESTDIR}/usr/local/bin
	cp -r build/brssl ${DESTDIR}/usr/local/bin
	chmod 755 ${DESTIR}/usr/local/bin/brssl

	mkdir -p ${DESTDIR}/usr/local/lib
	cp -r build/lib${pkgname}.so ${DESTDIR}/usr/local/lib
	chmod 644 ${DESTDIR}/usr/local/lib/lib${pkgname}.so
	cp -r build/lib${pkgname}.a ${DESTDIR}/usr/local/lib
	chmod 644 ${DESTDIR}/usr/local/lib/lib${pkgname}.a

	mkdir -p ${DESTDIR}/usr/local/include
	cp -r inc/* ${DESTDIR}/usr/local/include
}

neko_uninstall()
{
	rm -rf ${DESTDIR}/usr/local/bin/brssl
	rm -rf ${DESTDIR}/usr/local/lib/lib${pkgname}.so
	rm -rf ${DESTDIR}/usr/local/lib/lib${pkgname}.a
}
```
# Contributing
For contributing to the shell script, shellcheck is used to ensure portability. Please try and use only POSIX utilities (at the moment `wget` is the only non-standard utility as far as I know). When making a pull request, please make a branch with a relavent name and request to merge to the `develop` branch, unless you're making a pull request for a new package.
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
# TODO
* Add a license variable to the template to handle licenses of packages
* Add a `depends` variable to have templates be able to pull other dependency packages
* Add more build styles / packages
* Find a POSIX way to replace the `wget` solution for `neko_fetch`
