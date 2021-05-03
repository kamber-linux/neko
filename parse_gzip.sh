#!/bin/sh

READ_COUNTER=0
#echo "READ COUNTER + INIT: ${READ_COUNTER}"
magic=$(od -An -N 2 -t x2 "${1}" | head -n 1 | sed 's/^.*\ //')

[ "${magic}" != "8b1f" ] &&
	{
		printf "%s\n" "${1} is not a valid gzip archive"
		exit
	}
READ_COUNTER=$(( READ_COUNTER + 2 ))
#echo "READ COUNTER + MAGIC: ${READ_COUNTER}"

compression_method=$(od -An -N 1 -j ${READ_COUNTER} -t u1 "${1}" | head -n 1 | sed 's/.*\ //g; s/^0//')
if [ "${compression_method}" = "8" ]
then
	printf "%s\n" "Compression method: DEFLATE"
else
	printf "%s\n" "Compression method: UNKNOWN"
	exit
fi
READ_COUNTER=$((READ_COUNTER + 1))
#echo "READ COUNTER + COMPRESS METHOD: ${READ_COUNTER}"

flag=$(od -An -N 1 -j ${READ_COUNTER} -t u1 "${1}" | head -n 1 | sed 's/.*\ //g')

[ "$((flag & 16))" != "0" ] &&
	{
		printf "%s\n" "${1} has a COMMENT"
		HAS_COMMENT=true
	}
[ "$((flag & 8))" != "0" ] &&
	{
		printf "%s\n" "${1} has a NAME"
		HAS_NAME=true
	}
[ "$((flag & 4))" != "0" ] &&
	{
		printf "%s\n" "${1} has EXTRA"
		HAS_EXTRA=true
	}
[ "$((flag & 2))" != "0" ] &&
	{
		printf "%s\n" "${1} has HEADER_CRC"
		HAS_HEADER_CRC=true
	}
[ "$((flag & 1))" != "0" ] &&
	{
		printf "%s\n" "${1} is TEXT"
		IS_TEXT=true
	}
READ_COUNTER=$((READ_COUNTER + 1))
#echo "READ COUNTER + FLAG: ${READ_COUNTER}"

mod_time=$(od -An -N 4 -j ${READ_COUNTER} -t u4 "${1}" | head -n 1 | sed 's/.*\ //g')
printf "%s\n" "Last changed on: ${mod_time}"

READ_COUNTER=$((READ_COUNTER + 4))
#echo "READ COUNTER + MODTIME: ${READ_COUNTER}"

extra_flags=$(od -An -N 1 -j ${READ_COUNTER} -t u1 "${1}" | head -n 1 | sed 's/.*\ //g')
case "${extra_flags}" in
	"2") printf "%s\n" "Compression strength: best" ;;
	"4") printf "%s\n" "Compression strength: fast" ;;
	"0") printf "%s\n" "Compression strength: unknown (common)" ;;
	*) printf "%s\n" "Compression strength: UNKNOWN" ;;
esac

READ_COUNTER=$((READ_COUNTER + 1))
#echo "READ COUNTER + EXTRA FLAGS: ${READ_COUNTER}"

os=$(od -An -N 1 -j ${READ_COUNTER} -t u1 "${1}" | head -n 1 | sed 's/.*\ //g')
case "${os}" in
	"0") printf "%s\n" "Made on OS: FAT filesystem (MS-DOS, OS/2, NT/Win32)" ;;
	"1") printf "%s\n" "Made on OS: Amiga" ;;
	"2") printf "%s\n" "Made on OS: VMS (or OpenVMS)" ;;
	"3") printf "%s\n" "Made on OS: Unix" ;;
	"4") printf "%s\n" "Made on OS: VM / CMS" ;;
	"5") printf "%s\n" "Made on OS: Atari TOS" ;;
	"6") printf "%s\n" "Made on OS: HPFS filesystem (OS/2, NT)" ;;
	"7") printf "%s\n" "Made on OS: Macintosh" ;;
	"8") printf "%s\n" "Made on OS: Z-System" ;;
	"9") printf "%s\n" "Made on OS: CP/M" ;;
	"10") printf "%s\n" "Made on OS: TOPS-20" ;;
	"11") printf "%s\n" "Made on OS: NTFS filesystem (NT)" ;;
	"12") printf "%s\n" "Made on OS: QDOS" ;;
	"13") printf "%s\n" "Made on OS: Acorn RISCOS" ;;
	"255") printf "%s\n" "Made on OS: unknown" ;;
	*) printf "%s\n" "Made on OS: UNKNOWN" ;;
esac

READ_COUNTER=$((READ_COUNTER + 1))
#echo "READ COUNTER + OS: ${READ_COUNTER}"

[ -n "${HAS_EXTRA}" ] &&
	{
		len_subfields=$(od -An -N 2 -j "${READ_COUNTER}" -t u2 "${1}" | head -n 1 | sed 's/.*\ //g')
		READ_COUNTER=$((READ_COUNTER + 2))
		#echo "READ COUNTER + HAS_EXTRA: ${READ_COUNTER}"
		READ_COUNTER_EXTRA=0
		for subfield_count in $(seq "${len_subfields}")
		do
			#od -N 2 -j "${READ_COUNTER}" -t u2 "${1}"
			len_data=$(od -An -N 2 -j "$((READ_COUNTER + READ_COUNTER_EXTRA + 2))" -t u2 "${1}" | head -n 1 | sed 's/.*\ //g')
			#od -N "${len_data}" -j "$((READ_COUNTER + READ_COUNTER_EXTRA + 4))"
			READ_COUNTER_EXTRA=$((READ_COUNTER_EXTRA + len_data + 4))
		done
		READ_COUNTER=$((READ_COUNTER + READ_COUNTER_EXTRA))
		#echo "READ COUNTER + HAS_EXTRA: ${READ_COUNTER}"
		printf "EXTRA: %s\n" "${EXTRA}"
	}

[ -n "${HAS_NAME}" ] &&
	{
		NAME=""
		NAME_INDEX=0
		while [ "$(od -An -N 1 -j "$(( READ_COUNTER + NAME_INDEX ))" -t x1 "${1}" | head -n 1 | sed 's/.*\ //g; s/^0//')" != "0" ]
		do
			NAME="${NAME}$(od -An -N 1 -j "$(( READ_COUNTER + NAME_INDEX ))" -t c "${1}" | head -n 1 | sed 's/.*\ //g')"
			NAME_INDEX=$(( NAME_INDEX + 1 ))
		done
		unset NAME_INDEX
		NAME_LENGTH=${#NAME}
		READ_COUNTER=$(( READ_COUNTER + NAME_LENGTH + 1 ))
		#echo "READ COUNTER + HAS_NAME: ${READ_COUNTER}"
		printf "NAME: %s\n" "${NAME}"
	}

[ -n "${HAS_COMMENT}" ] &&
	{
		COMMENT=""
		COMMENT_INDEX=0
		while [ "$(od -An -N 1 -j "$(( READ_COUNTER + COMMENT_INDEX ))" -t x1 "${1}" | head -n 1 | sed 's/.*\ //g; s/^0//')" != "0" ]
		do
			COMMENT="${COMMENT}$(od -An -N 1 -j "$(( READ_COUNTER + COMMENT_INDEX ))" -t c "${1}" | head -n 1 | sed 's/.*\ //g')"
			COMMENT_INDEX=$(( COMMENT_INDEX + 1 ))
		done
		unset COMMENT_INDEX
		COMMENT_LENGTH=${#COMMENT}
		READ_COUNTER=$(( READ_COUNTER + COMMENT_LENGTH + 1 ))
		#echo "READ COUNTER + HAS_COMMENT: ${READ_COUNTER}"
		printf "COMMENT: %s\n" "${COMMENT}"
	}

[ -n "${HAS_HEADER_CRC}" ] &&
	{
		header_crc16=$(od -An -N 2 -j "${READ_COUNTER}" -t u2 "${1}" | head -n 1 | sed 's/.*\ //g')
		READ_COUNTER=$(( READ_COUNTER + 2 ))
		#echo "READ COUNTER HAS_HEADER_CRC: ${READ_COUNTER}"
		printf "HEADER_CRC: %s\n" "${header_crc16}"
	}

COMPRESSED_SIZE=$(wc -c "${1}" | cut -d' ' -f1)
COMPRESSED_SIZE=$(( COMPRESSED_SIZE - READ_COUNTER - 8 ))

#dd if="${1}" of="benchmark" bs=1 count="${COMPRESSED_SIZE}" skip="${READ_COUNTER}"
dd if="${1}" of="${NAME:-${1%.*}}" ibs="${COMPRESSED_SIZE}" obs=1 seek="${READ_COUNTER}" count=1

READ_COUNTER=$(( READ_COUNTER + COMPRESSED_SIZE ))
#echo "READ COUNTER + COMPRESSED_SIZE: ${READ_COUNTER}"

body_crc32=$(od -An -N 4 -j "${READ_COUNTER}" -t u4 "${1}" | head -n 1 | sed 's/.*\ //g')
#echo "${COMPRESSED_SIZE}"
READ_COUNTER=$(( READ_COUNTER + 4 ))

len_uncompressed=$(od -An -N 4 -j "${READ_COUNTER}" -t u4 "${1}" | head -n 1 | sed 's/.*\ //g')
#echo "${len_uncompressed}"
#END OF THE FILE BITCHES
