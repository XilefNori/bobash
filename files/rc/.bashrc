# Init -------------------------------------------------------------

SRC="${BASH_SOURCE[0]//\\//}"
DIR="$(cd -P "${SRC%/*}" > /dev/null && pwd)"

export BOBASH_DIR
# export

BOBASH_DIR="$DIR/.bobash"
[[ -d $BOBASH_DIR/rc ]] || BOBASH_DIR="$(cd -P "$DIR/.." > /dev/null && pwd)"
[[ -d $BOBASH_DIR/rc ]] || { echo "BOBASH_DIR rc [$BOBASH_DIR/rc] is not found!"; return; }

# Interactive shell
BOBASH_INTERACTIVE=
case $- in
    *i*) BOBASH_INTERACTIVE=1
esac

if [[ $BOBASH_INTERACTIVE -gt 0 ]]; then
    declare load_path=''
    for i in ${BASH_SOURCE[@]:1:2}; do
        load_path="$load_path -> $i"
    done

    load_path="$(echo "$load_path" | sed "s:$BOBASH_DIR:\$BOBASH_DIR:g; s:$HOME:~:g")"

    echo "Loading [${BASH_SOURCE[0]}$load_path]"
fi

# Start -------------------------------------------------------------

[[ -f ~/.bashrc-local-pre ]] && source ~/.bashrc-local-pre

shopt -u expand_aliases

[[ -n $BOBASH_INTERACTIVE ]] && echo "Loading $BOBASH_DIR/rc/.bashrc.files ..." >&2

source $BOBASH_DIR/rc/.bashrc.files

# Local changes
[[ -f ~/.bashrc-local-post ]] && source ~/.bashrc-local-post

shopt -s expand_aliases

path-readd "$BOBASH_DIR/bin"
path-readd "$HOME/bin"

export BOBASH_LOADED=1

# cat ~/.cls
# echo -n $'\033'c
