#!/bin/sh

usage()
{
	printf "%s\n" "usage: ${0} FILE"
	exit
}
[ "$#" != "1" ] || [ ! -f "${1}" ] && usage

# how many bytes in the file we are in
# starts at 0
READ_COUNTER=0

# usage: change VALUE (MATH EXPRESSION)
# modify a value depending on itself
# e.g. - change INDEX + 1 + VALUE
# INDEX = INDEX + 1 + VALUE
change()
{
	CHANGE_VAR="${1}"
	shift 1
	eval "${CHANGE_VAR}"="$(( $CHANGE_VAR $@ ))"
	unset CHANGE_VAR
}

# usage: bytes <number of bytes> <type of read> <additional bytes counter>
# alias out becuase we're always expecting an argument - ${1}
# e.g. - bytes 1 x1 6
# reads 1 x1 byte 6 bytes ahead of current READ_COUNTER
# e.g. - bytes 1 x1 0
# current x1 byte
bytes()
{
	od -An -N "${2}" -j "$(( READ_COUNTER + ${4} ))" -t "${3}" "${1}" |
		sed "s/\s*//g; /^$/ d"
}
alias bytes='bytes "${1}"'

# usage: read_bytes VARIABLE <number of bytes> <type of read>
# e.g. - read_bytes os 1 u1
# will store one u1 byte to os variable
read_bytes()
{
	eval "${2}"="$(od -An -N "${3}" -j "${READ_COUNTER}" -t "${4}" "${1}" |
		sed "s/\s*//g; /^$/ d")"
	change READ_COUNTER + "${3}"
}
alias read_bytes='read_bytes "${1}"'

# Read a null terminated string
# can't use aliased functions due to variable scope - so it's messy, but works
# e.g. - strz_process VAR
# will process null terminated string into VAR
strz_process()
{
	eval "STRING"=""
	COUNTER_INDEX=0
	# s/00/0 to work with suckless od
	while [ "$(od -An -N 1 -t x1 -j "$(( READ_COUNTER + COUNTER_INDEX ))" "${1}" |
		sed 's/\s*//g; /^$/ d; s/00/0/')" != "0" ]
	do
		eval STRING="${STRING}$(od -An -N 1 -t c -j\
			"$(( READ_COUNTER + COUNTER_INDEX ))" "${1}" | sed 's/\s*//g; /^$/ d')"
		change COUNTER_INDEX + 1
	done
	unset COUNTER_INDEX
	eval "${2}"="${STRING}"
	STRING_LENGTH="${#STRING}"
	# + 1 for the null byte itself
	change READ_COUNTER + STRING_LENGTH + 1
	unset STRING
	unset STRING_LENGTH
	unset STRING
}
alias strz_process='strz_process "${1}"'

read_bytes magic 2 x2
[ "${magic}" != "8b1f" ] &&
	{
		printf "%s\n" "${1} is not a valid gzip archive"
		exit
	}

read_bytes compression_method 1 u1
printf "%s" "Compression method: "
case "${compression_method}" in
	"8") printf "%s\n" "deflate" ;;
	*) printf "%s\n" "UNKNOWN"; exit ;;
esac

read_bytes flag 1 u1
[ "$(( flag & 16 ))" != "0" ] && HAS_COMMENT="true"
[ "$(( flag & 8 ))" != "0" ] && HAS_NAME="true"
[ "$(( flag & 4 ))" != "0" ] && HAS_EXTRA="true"
[ "$(( flag & 2 ))" != "0" ] && HAS_HEADER_CRC="true"
[ "$(( flag & 1 ))" != "0" ] && IS_TEXT="true"

read_bytes mod_time 4 u4
printf "%s\n" "Mod time: ${mod_time}"

read_bytes extra_flags 1 u1
printf "%s" "Compression strength: "
case "${extra_flags}" in
	"2") printf "%s\n" "best" ;;
	"4") printf "%s\n" "fast" ;;
	"0") printf "%s\n" "unknown (common)" ;;
	*) printf "%s\n" "UNKNOWN" ;;
esac

read_bytes os 1 u1
printf "%s" "Made on OS: "
case "${os}" in
	"0") printf "%s\n" "FAT filesystem (MS-DOS, OS/2, NT/Win32)" ;;
	"1") printf "%s\n" "Amiga" ;;
	"2") printf "%s\n" "VMS (or OpenVMS)" ;;
	"3") printf "%s\n" "Unix" ;;
	"4") printf "%s\n" "VM / CMS" ;;
	"5") printf "%s\n" "Atari TOS" ;;
	"6") printf "%s\n" "HPFS filesystem (OS/2, NT)" ;;
	"7") printf "%s\n" "Macintosh" ;;
	"8") printf "%s\n" "Z-System" ;;
	"9") printf "%s\n" "CP/M" ;;
	"10") printf "%s\n" "TOPS-20" ;;
	"11") printf "%s\n" "NTFS filesystem (NT)" ;;
	"12") printf "%s\n" "QDOS" ;;
	"13") printf "%s\n" "Acorn RISCOS" ;;
	"255") printf "%s\n" "unknown" ;;
	*) printf "%s\n" "UNKNOWN" ;;
esac

# might be broken - need a gzip with HAS_EXTRA flag to test
[ "${HAS_EXTRA}" = "true" ] &&
	{
		read_bytes len_subfields 2 u2
		HAS_EXTRA_COUNTER=0
		for subfield_count in $(seq "${len_subfields}")
		do
			change READ_COUNTER + HAS_EXTRA_COUNTER
			read_bytes len_data 2 u2
			change HAS_EXTRA_COUNTER + READ_COUNTER
		done
		change READ_COUNTER + HAS_EXTRA_COUNTER
		unset HAS_EXTRA_COUNTER
		printf "%s\n" "EXTRA: ${EXTRA}"
	}

[ "${HAS_NAME}" = "true" ] &&
	{
		strz_process NAME
		printf "%s\n" "NAME: ${NAME}"
	}

[ "${HAS_COMMENT}" = "true" ] &&
	{
		strz_process COMMENT
		printf "%s\n" "COMMENT: ${COMMENT}"
	}

[ "${HAS_HEADER_CRC}" = "true" ] &&
	{
		read_bytes header_crc16 2 u2
		printf "%s\n" "HEADER_CRC: ${header_crc16}"
	}

COMPRESSED_SIZE=$(wc -c "${1}" | cut -d' ' -f1)
change COMPRESSED_SIZE - READ_COUNTER - 8
# This is where we start handling deflate data stream in the future
#dd if="${1}" of="${OUTPUT}" ibs="${COMPRESSED_SIZE}" obs=1 seek="${READ_COUNTER}" count=1
change READ_COUNTER + COMPRESSED_SIZE

# So that output place has same behaviour whether NAME is set or not
[ -z "${NAME}" ] && OUTPUT="${1%.*}" || OUTPUT="$(dirname "${1}")/${NAME}"

read_bytes body_crc32 4 u4
read_bytes len_uncompressed 4 u4
# END OF FILE
# Because the size of the uncompressed data must be able to be represented in 4
# bytes, if the uncompressed data is bigger then 2^32 - 1, this makes for buggy
# behaviour in both this script and gunzip -l. 2^32 - 1 bytes is about 5G
# Will still compress / decompress as the deflate algorythm is size complete
# (can work on arbitrary file size), just querying the file size will be broken
# reproduce the bug in this script and gunzip -l on linux:
# fallocate -l $(( 2 ** 32 + 1 )) FILE; gzip FILE; gunzip -l FILE.gz
[ "${COMPRESSED_SIZE}" -gt "${len_uncompressed}" ] &&
	len_uncompressed="OVERFLOW"
# Still possible for undetected overflow if it loops enough
# This is a fundamental flaw in the gzip format...

printf "%s\n" "Uncompressed name: $(basename "${OUTPUT}")"
printf "%s\n" "Compressed data size: ${COMPRESSED_SIZE}"
printf "%s\n" "Compressed file size: ${READ_COUNTER}"
printf "%s\n" "Uncompressed size: ${len_uncompressed}"
