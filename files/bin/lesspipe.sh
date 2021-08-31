#!/usr/bin/env bash

declare -f bb_module > /dev/null || source $BOBASH_DIR/sys/module.in
bb_module config colors filters > /dev/null

fname="$1"

if [[ $USYSTEM == 'cygwin' ]]; then
	fname="$(cygpath -m "$fname")"
fi

markdown2man() {
    declare fname="$1"
    declare title="$(basename "$fname" .md)"

    cat "$1"                                                    |
    sed 's: _: :g; s:_ : :g; s:```:=+=:g; s:`:_:g; s:=+=:```:g' |
    sed '1 { s:<!-- # ::; s:-->::; }'                           |
    pandoc -s -f markdown -t man                                |
    sed '/^.TH/s:^.*:.TH "'"$title"'" "1" "" "" "":'            |
    preconv                                                     |
    nroff -Tutf8 -mandoc -c
}

case "$fname" in
    *.log    ) colorize-log "$fname"                ;;
    *.log.gz ) zcat         "$fname" | colorize-log ;;
    *.log.bz2) bzcat        "$fname" | colorize-log ;;
    *.gz     ) zcat         "$fname"                ;;
    *.bz2    ) bzcat        "$fname"                ;;
    *.md     ) markdown2man "$fname"                ;;
            *) cat          "$fname"                ;;
esac 2>/dev/null

# [ ! -t 0 ] && stdin=1
# case "$fname" in
#     *.log)
#         if [[ -n $stdin ]]; then
#             colorize-log -
#         else
#             colorize-log "$fname"
#         fi 2>/dev/null
#     ;;
# esac
