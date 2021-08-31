#!/usr/bin/env bash

# Backup

# Init ----------------------------------------------------------------------

# SRC="$(echo ${BASH_SOURCE[0]} | sed 's:\\:/:g')"
SRC="${BASH_SOURCE[0]//\\//}"
DIR="$(cd -P "${SRC%/*}" > /dev/null && pwd)"

#--------------------------------------------------------------------------
# Utils
#--------------------------------------------------------------------------

error() { echo "[`basename $SRC`:$2] $1" >&2; exit 1; }

#--------------------------------------------------------------------------
# Settings
#--------------------------------------------------------------------------

name=$(basename $SRC)
name=${name/-cfg*}

dr_cfg='.bobash'
fr_arc='bobash.tar.gz'

dr_bak="$dr_cfg/backup"
dr_rc="$dr_cfg/rc"

#--------------------------------------------------------------------------
# Help
#--------------------------------------------------------------------------

usage() {
    :
}

#--------------------------------------------------------------------------
# Arguments
#--------------------------------------------------------------------------

declare action force homedir yes dist keep_dist

[ $# -eq 0  ] && { usage; exit; }

# -- Arguments --
declare flags="Kd:a:h:fy" OPTIND=1
declare -a params
for (( ; OPTIND <= $#; )) do
    getopts "$flags" flag && { case $flag in
        K) keep_dist=1 ;;
        d) dist="$OPTARG"  ;;
        a) action="$OPTARG"  ;;
        h) homedir="$OPTARG" ;;
        f) force='true'      ;;
        y) yes='true'        ;;
	esac; } || {
        params+=("${!OPTIND}"); ((OPTIND++))
    }
done

da_home="$homedir"

[[ ! -d "$da_home" ]] && mkdir "$da_home"

[ -z "$da_home" ] && da_home="$HOME"

da_home="$(cd -P "$da_home" > /dev/null && pwd)"

[[ -n $dist ]] && {
    fa_arc="$(realpath "$dist")"
} || {
    fa_arc="$DIR/$fr_arc"
}

da_bak="$da_home/$dr_bak"
da_cfg="$da_home/$dr_cfg"
da_rc="$da_home/$dr_rc"

da_install="$da_cfg/install"

#--------------------------------------------------------------------------
# Tests
#--------------------------------------------------------------------------

case "$action" in
    install|reinstall)
        [[ ! -f "$fa_arc" ]] && { error "Package file [$fa_arc] not found!" $LINENO; }
    ;;
esac

#--------------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------------

simple_ask() {
    while true
    do
        read -p "$* [y/n]: "
        if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then return 0; fi
        if [ "$REPLY" == "n" ] || [ "$REPLY" == "N" ]; then return 1; fi
        echo
        echo "Please enter 'y/Y' or 'n/N'!"
    done
}

install() {
    echo "Installing configuration ..."

    echo "Untar config files to [$da_cfg] ..."
    if [ ! -d "$da_cfg" ]; then
        mkdir -p "$da_cfg"
    fi

    if [ ! -d "$da_cfg" ]; then
        error "Cannot create config dir [$da_cfg]"
    fi

    tar -mxzf "$fa_arc" -C "$da_cfg"

    if [ ! -d $da_bak ]; then
        mkdir -p $da_bak
    fi

    files=(`find "$da_rc" -maxdepth 1 -mindepth 1 | sed "s:${da_rc}/::"`)

    echo "Moving old config rc files to [$da_bak] ..."
    for i in "${files[@]}"; do
        if [[ -e $i && ! -L $i ]]; then
            mv  "$i" "$da_bak/"
        fi
    done

    echo "Making links to new config rc files ..."
    for i in "${files[@]}"; do
        ln -sf "$dr_rc/$i"  "$i"
    done

    # sed -i -b -e "s|%BOBASH_DIR%|$da_cfg|" "$da_cfg/rc/.bashrc"
    sed -i -e "s|%BOBASH_DIR%|$da_cfg|" "$da_cfg/rc/.bashrc"

    find "$da_cfg/bin" -type f | xargs chmod +x

    if [[ -d $da_install ]]; then
        echo "Run install scripts from [$da_install] ..."

        find "$da_install" -type f -name '*.sh' | while IFS=$'\n' read -r fa_install_script; do
            chmod +x "$fa_install_script"
            fa_install_log="${fa_install_script%.*}.log"

            echo " - ${fa_install_script##*/} > ${fa_install_log##*/}"

            BOBASH_DIR="$da_cfg" HOME="$da_home" "$fa_install_script" > "${fa_install_log}"
        done
    fi
}

uninstall() {
    echo "Uninstalling [$da_cfg]"

    [[ ! -d "$da_cfg" ]] && {
        echo "No bobash dir: [$da_cfg]"
        return 0;
    }

    files=(`find $da_rc -maxdepth 1 -mindepth 1 | sed "s:${da_rc}/::"`)

    echo "Removing links"
    for i in "${files[@]}"; do
        [ -L $i ] && rm -f $i
    done

    if [[ -d $da_bak ]]; then
        echo "Restoring backup [$da_bak]"
        find  "$da_bak" -mindepth 1 -maxdepth 1 -exec mv {} . \;
        rmdir "$da_bak"
    fi

    echo "Removing [$da_cfg]"
    rm -rf "$da_cfg"
}

reinstall() {
    uninstall
    install
}

#--------------------------------------------------------------------------
# Operate
#--------------------------------------------------------------------------

# for i in "${files[@]}"; do
#     echo $i
# done
operate() {
    echo "Preparing to $action $name"
    echo
    echo "-- Configuration --"
    echo

    case "$action" in
        install|reinstall)
            echo "Package file: $fa_arc"
        ;;
    esac

    echo "Install dir : $da_cfg"
    echo "Backup  dir : $da_bak"
    echo

    if ! simple_ask 'Continue?'; then
        echo 'Canceled by user'
        exit 1
    fi

    echo 'Please wait...'

    pushd "$da_home" > /dev/null

    case "$action" in
        "install"    )  install    ;; # Инсталлировать
        "uninstall"  )  uninstall  ;; # Деинсталлировать
        "reinstall"  )  reinstall  ;; # РеИнсталлировать
                    *)  echo 'Указаны неверные параметры' ;;
    esac

    popd     > /dev/null

    echo
    echo 'Completed.'

    [[ -f "$fa_arc" && -z $keep_dist ]] &&  {
        echo "Removing package file: $fa_arc"

        rm -f "$fa_arc"
    }
}

if [ -z "$yes" ]; then
    operate
else
    yes | operate
fi
