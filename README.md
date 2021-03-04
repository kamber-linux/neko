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

The templates will patch in to use TCC by default.
