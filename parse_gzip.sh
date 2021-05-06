#!/bin/sh

usage()
{
	printf "%s\n" "usage: ${0} FILE"
	exit
}
[ -z "${1}" ] || [ "$#" != "1" ] || [ ! -f "$1" ] && usage

# how many bytes in the file were in
# starts at 0
READ_COUNTER=0

# usage: bytes <number of bytes> <type of read> <additional bytes counter>
# alias out becuase we're always expecting an argument - ${1}
bytes()
{
	od -An -N "${2}" -j "$(( READ_COUNTER + ${4} ))" -t "${3}" "${1}" | sed "s/\s*//g; /^$/ d"
}
alias bytes='bytes "${1}"'

# usage: read_bytes VAR <number of bytes> <type of read>
# VAR is name of variable
# e.g. - read_bytes os 1 u1 will store one u1 byte to os variable
read_bytes()
{
	eval "${2}"="$(od -An -N "${3}" -j "${READ_COUNTER}" -t "${4}" "${1}" | sed "s/\s*//g; /^$/ d")"
	READ_COUNTER=$(( READ_COUNTER + ${3} ))
}
alias read_bytes='read_bytes "${1}"'

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

[ "${HAS_EXTRA}" = "true" ] &&
	{
		read_bytes len_subfields 2 u2
		HAS_EXTRA_COUNTER=0
		for subfield_count in $(seq "${len_subfields}")
		do
			READ_COUNTER=$(( READ_COUNTER + HAS_EXTRA_COUNTER ))
			read_bytes len_data 2 u2
			HAS_EXTRA_COUNTER=$(( HAS_EXTRA_COUNTER + READ_COUNTER ))
		done
		READ_COUNTER=$(( READ_COUNTER + HAS_EXTRA_COUNTER ))
		unset HAS_EXTRA_COUNTER
		printf "%s\n" "EXTRA: ${EXTRA}"
	}

[ "${HAS_NAME}" = "true" ] &&
	{
		NAME=""
		NAME_INDEX=0
		# s/00/0 to work with suckless od
		while [ "$(bytes 1 x1 "${NAME_INDEX}" | sed "s/00/0/g")" != "0" ]
		do
			NAME="${NAME}$(bytes 1 c "${NAME_INDEX}")"
			NAME_INDEX=$(( NAME_INDEX + 1 ))
		done
		unset NAME_INDEX
		NAME_LENGTH=${#NAME}
		READ_COUNTER=$(( READ_COUNTER + NAME_LENGTH + 1 ))
		unset NAME_LENGTH
		printf "%s\n" "NAME: ${NAME}"
	}

[ "${HAS_COMMENT}" = "true" ] &&
	{
		COMMENT=""
		COMMENT_INDEX=0
		while [ "$(bytes 1 x1 "${COMMENT_INDEX}" | sed "s/00/0/g")" != "0" ]
		do
			COMMENT="${COMMENT}$(bytes 1 c "${COMMENT_INDEX}")"
			COMMENT_INDEX=$(( COMMENT_INDEX + 1 ))
		done
		unset COMMENT_INDEX
		COMMENT_LENGTH=${#COMMENT}
		READ_COUNTER=$(( READ_COUNTER + COMMENT_LENGTH + 1 ))
		unset COMMENT_LENGTH
		printf "%s\n" "COMMENT: ${COMMENT}"
	}

[ "${HAS_HEADER_CRC}" = "true" ] &&
	{
		read_bytes header_crc16 2 u2
		printf "%s\n" "HEADER_CRC: ${header_crc16}"
	}

COMPRESSED_SIZE=$(wc -c "${1}" | cut -d' ' -f1)
COMPRESSED_SIZE=$(( COMPRESSED_SIZE - READ_COUNTER - 8 ))

dd if="${1}" of="${NAME:-${1%.*}}" ibs="${COMPRESSED_SIZE}" obs=1 seek="${READ_COUNTER}" count=1
READ_COUNTER=$(( READ_COUNTER + COMPRESSED_SIZE ))

read_bytes body_crc32 4 u4
read_bytes len_uncompressed 4 u4
# END OF FILE
