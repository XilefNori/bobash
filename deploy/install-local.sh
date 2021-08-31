#!/usr/bin/env bash

# Init ----------------------------------------------------------------------

SRC="${BASH_SOURCE[0]//\\//}"
[[ -z "$SRC" ]] && SRC="$(readlink -f $0)"
DIR="$(cd -P "${SRC%/*}" > /dev/null && pwd)"

# Run -----------------------------------------------------------------------

declare real

# -- Arguments --
declare flags="rR" OPTIND=1
declare -a params
for (( ; OPTIND <= $#; )) do
    if getopts "$flags" flag; then case $flag in
          r|R) real=1 ;;
    esac; else
        params+=("${!OPTIND}"); ((OPTIND++))
    fi
done

if [[ $real -gt 0 ]]; then
    "$DIR/deploy.sh" local reinstall
else
    "$DIR/deploy.sh" local reinstall -H "$HOME/bobash-test"
fi
