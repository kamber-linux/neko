#!/bin/sh

DESTDIR="${HOME}"/.local/share/neko/master

find "${DESTDIR}" -type f | sed "s|${DESTDIR}||" |
	while read -r file
	do
		printf "%s %s\n" "${file}" "$(cksum "${DESTDIR}${file}" | cut -d' ' -f1)"
	done
