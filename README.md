# About
`neko` is a package builder that is heavily inspired off of xbps from VOID linux. Mainly just a learning experience - would love ideas / help ~

# Usage
Just have a POSIX shell, and download `neko`, then try out one of the templates.
```
./neko em bearssl
./neko emerge st
```
The build will be in `master/${wrksrc}` where `${wrksrc}` is the package name and version.
Clean up the master directory with `./neko-src clean`.

# Making a template
I really love the way `xbps-src` templates are formatted, and it's very similar. Make a directory in `srcpkgs` with the package name `<pkg>`, then make a plain text file `template` within it. Give a `pkgname`, `version`, `homepage`, `distfiles`, and `checksum` (that's all for now).
## Example
In `srcpkgs/st`, the `template` file looks like
```
pkgname=st
version=0.8.4
homepage=https://${pkgname}.suckless.org
distfiles=https://dl.suckless.org/${pkgname}/${pkgname}-${version}.tar.gz
checksum="d42d3ceceb4d6a65e32e90a5336e3d446db612c3fbd9ebc1780bc6c9a03346a6"
```

# Making patches (advice appreciated, I'm bad)
To make a patch, go to the source folder and make two folders, `a` and `b`. Copy the file you want to edit into `a`, and copy that into `b`: `cp a/<file> b`. Edit `b/<file>` to the changes you want. Then, `diff -Naur a/<file> b/<file> > <patch_name>.patch`. Make a folder in `srcpkgs/<pkg>` called `patches`, and add the patch there.

The templates will patch in to use TCC by default.
