# About
`neko` is a package builder that is heavily inspired off of xbps from VOID linux. Mainly just a learning experience - would love ideas / help ~

# Usage
Just have a POSIX shell, and download `neko`, then try out one of the templates.
```
./neko em bearssl
./neko emerge sbase
```
Note that, by default, you will need TCC (tiny c compiler) to use it. Feel free to remove patches if you want.
The build will be in `master/${wrksrc}` where `${wrksrc}` is the package name and version.
Clean up the master directory with `./neko-src clean`.

# Making a template
I really love the way `xbps-src` templates are formatted, and it's very similar. Make a directory in `srcpkgs` with the package name `<pkg>`, then make a plain text file `template` within it. Give a `pkgname`, `version`, `distfiles` (or `giturl`), `build_style` , and `checksum` (if using `distfiles`) (that's all for now).
## Example
In `srcpkgs/st`, the `template` file looks like
```
pkgname=st
version=0.8.4
distfiles="https://dl.suckless.org/${pkgname}/${pkgname}-${version}.tar.gz"
checksum=d42d3ceceb4d6a65e32e90a5336e3d446db612c3fbd9ebc1780bc6c9a03346a6
build_style=makefile
```
Git builds are also planned to be supported. Instead of specifying `distfiles`, just specify `giturl` and add "-git" to the package directory name and it should work the same.

# Making patches (advice appreciated, I'm bad)
To make a patch, go to the source folder and make two folders, `a` and `b`. Copy the file you want to edit into `a`, and copy that into `b`: `cp a/<file> b`. Edit `b/<file>` to the changes you want. Then, `diff -Naur a/<file> b/<file> > <patch_name>.patch`. Make a folder in `srcpkgs/<pkg>` called `patches`, and add the patch there.

# TODO
* Write a wget alternative in SHELL using BearSSL libraries (make more SSL library agnostic once done)
* Add in more explicit pre and post steps to make it more fail safe
* Add more build styles
* Add more packages
