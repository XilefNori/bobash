#!/usr/bin/env bash

# Init ----------------------------------------------------------------------

SRC="${BASH_SOURCE[0]//\\//}"
[[ -z "$SRC" ]] && SRC="$(readlink -f $0)"
DIR="$(cd -P "${SRC%/*}" > /dev/null && pwd)"

# DIR="$(cd ${0%/*} > /dev/null && pwd)"

ROOT_DIR="$(cd $DIR/.. > /dev/null && pwd)"

declare file_only=0
declare da_files

if [[ -d "$ROOT_DIR/files" ]]; then
    da_files="$ROOT_DIR/files"
else
    da_files="$ROOT_DIR"
    file_only=1
fi

declare keep_dist_at_target=
declare fr_dist_remote='bobash.tar.gz'
declare fa_dist

# Help ---------------------------------------------------------------------

help() {
cat << 'E'
deploy <config> [<action>] - Deploy bobash build to ssh-host/docker/kube nodes

<config> - name of build settings in 'nodes' file
<action> - action to commit with build [default: reinstall]
  - install  : install bobash to node
  - uninstall: uninstall bobash from node
  - reinstall: uninstall + install

1. Creates bobash build [optional] setup by build settings
2. Deploys bobash build to target node
3. Enters node [optional]

== Options ====================================================================

- D - DRY mode: print only build and deploy infomation (move verbose) and exit

- f <file> - Do not build, use file as build archive (not deleted on delpoyment)

-- Build settings --

- d - add docker/deploy directories to build
- c - deploy channel
- h - build host config
- o - build os config

-- Deployment --

- t - target node (ssh-host/docker/kube) [if not set <config> is used instead]
- H - HOME dir on target node for deployment

- K - do not delete build arhive from node after deployment
- e - enter node after deployment
- E - just enter node (don't do deployment)

== Config file ["$BOBASH_DIR_DEPLOY/nodes"] ===================================

Config file stores settings for bobash builds:

# name         : channel : os     : host             : home-path

box2           : ssh     : ubuntu : project          : ~
dc             : docker  : alpine : project-dc       : /bobash/home
kube           : kube    : alpine : project-dc       : /bobash/home
local          : fs      : cygwin : localhost.cygwin : ~
default        :         : debian :                  : ~/.config/user/bob

name      - build/node name
channel   - deployment channel (ssh/docker/kube/fs)
os        - build os   (os   bobash dir)
host      - build host (host bobash dir)
home-path - HOME dir for bobash deployment

E
}

declare p
for p in "${@}"; do [[ $p == "-?" || $p == '--help' ]] && { help | less -FX; exit; }; done

# System -------------------------------------------------------------------

error() {
    echo "$@"

    onExit
    exit 1
}

source-lib() {
    declare fa_file="$da_files/$1"

    source "$fa_file" || error "Cannot source file [$fa_file]"
}

onExit() {
    if [[ -n $fa_dist && -f $fa_dist && -z $dist_keep ]]; then
        rm -f "$fa_dist"
    fi
}

# Include -------------------------------------------------------------------

[[ -z $BOBASH_DIR ]] && export BOBASH_NODES_FILE="$DIR/nodes"

source-lib "lib/complete.in"
source-lib "lib/bobash-node.in"
source-lib "lib/cached.in"
source-lib "lib/touch.in"

source-lib "sys/distro.in"
source-lib "lib/functions.in"

source-lib "ext/ssh.in"
source-lib "ext/docker.in"
source-lib "ext/kube.in"

# Functions -----------------------------------------------------------------

cat-action() {
    declare action="$1"

    declare fa_action="$DIR/action/$action.ssh"
    [[ ! -f "$fa_action" ]] && error "Action file [$fa_action] not exists!"

    declare keep=
    [[ -n $keep_dist_at_target ]] && keep='-K'

    sed "s:%HOME%:$target_home:g; s:%KEEP_DIST%:$keep:" "$fa_action"
}

deploy-fs() {
    mkdir              -p "$target_home/"
    mv -f "$fa_dist"      "$target_home/$fr_dist_remote"
    cp -f "$fa_installer" "$target_home/"

    cat-action "$action" | bash
}

deploy-ssh() {
    [[ $enter -eq 2 ]] && {
        echo "ONLY ENTER to [$target_host:$target_home]"

        ssh "$target_host" -h "$target_home"

        exit
    }

    echo "Deploying to $target_host:$target_home ..."

    cat-action "prepare" | ssh-exec "$target_host"

    [[ "$action" = "prepare" ]] && return

    if [[ "$action" = "install" || "$action" = "reinstall" ]]; then
        echo scp "$fa_dist" "$target_host:$target_home/$fr_dist_remote"
             scp "$fa_dist" "$target_host:$target_home/$fr_dist_remote" || error "Cannot cp [$fa_dist] -> [$target_host:$target_home/$fr_dist_remote]"
    fi

    scp "$fa_installer" "$target_host:$target_home"

    cat-action "$action" | ssh-exec "$target_host" && {
        [[ $enter -gt 0 ]] && {
            echo
            echo "-- ENTER to [$target_host:$target_home] --"
            echo

            ssh "$target_host" -h "$target_home"

            exit
        }
    }

    # {
    #     ssh-exec-input.exp "$target_host"
    #     ssh-exec "$target_host"
    # }
}

deploy-docker() {
    if [[ ${target_home:0:1} == '~' ]]; then
        declare home="$(docker-env "$target_host" HOME -v)" || error "Cannot get home from [$target_host]"
        target_home="${target_home/\~/$home}"
    fi

    [[ $enter -eq 2 ]] && {
        echo "ONLY ENTER to [$target_host:$target_home]"

        docker-enter "$target_host" -h "$target_home" -v

        exit
    }

    echo "Deploying to $target_host:$target_home ..."

    cat-action "prepare" | docker-exec "$target_host"

    [[ "$action" = "prepare" ]] && return

    if [[ "$action" = "install" || "$action" = "reinstall" ]]; then
        docker-cp "$target_host" "$fa_dist" "$target_home/$fr_dist_remote" -v || error "Cannot cp [$fa_dist] -> [$target_host:$target_home/$fr_dist_remote]"
    fi

    docker-cp "$target_host" "$fa_installer" "$target_home" -v

    cat-action "$action" | docker-exec "$target_host" && {
        [[ $enter -gt 0 ]] && {
            echo
            echo "-- ENTER to [$target_host:$target_home] --"
            echo

            docker-enter "$target_host" -h "$target_home" -v

            exit
        }
    }
}

deploy-kube() {
    if [[ ${target_home:0:1} == '~' ]]; then
        declare home="$(kube-env "$target_host" HOME -v)" || error "Cannot get home from [$target_host]"
        target_home="${target_home/\~/$home}"
    fi

    [[ $enter -eq 2 ]] && {
        echo "ONLY ENTER to [$target_host:$target_home]"

        kube-enter "$target_host" -h "$target_home" -v

        exit
    }

    echo "Deploying to $target_host:$target_home ..."

    cat-action "prepare" | kube-exec "$target_host"

    [[ "$action" = "prepare" ]] && return

    if [[ "$action" = "install" || "$action" = "reinstall" ]]; then
        kube-cp "$target_host" "$fa_dist" "$target_home/$fr_dist_remote" -v || error "Cannot cp [$fa_dist] -> [$target_host:$target_home]"
    fi

    kube-cp "$target_host" "$fa_installer" "$target_home"


    cat-action "$action" | kube-exec "$target_host" && {
        [[ $enter -gt 0 ]] && {
            echo
            echo "-- ENTER to [$target_host:$target_home] --"
            echo

            kube-enter "$target_host" -h "$target_home" -v

            exit
        }
    }

}

exec-channel() {
    case $channel in
        ssh|kube|docker) exec=($channel-exec $target_host) ;;
                     fs) exec=(bash)                       ;;
    esac

    ${exec[@]}
}

get-target-os() {
    os="$(func-echo-call distro-id | exec-channel)"

    config-os-exists "$os" || {
        os="$(func-echo-call distro-system | exec-channel)"
    }

    echo "$os"
}

config-os-exists()   { [[ -d $da_files/os/$1 ]]; }
config-host-exists() { [[ -d $da_files/host/$1 ]]; }

# Arguments -----------------------------------------------------------------

declare -a build_opts
declare debug channel host_config os_config target_host target_home enter fa_dist

declare flags="dODc:t:f:h:o:H:eEK" OPTIND=1
declare -a params
for (( ; OPTIND <= $#; )) do
    getopts "$flags" flag && { case $flag in
        O) _complete-cmd-options "$flags"; exit ;;
        D) debug=1 ;;
        d) build_opts+=(-d)  ;;

        c) channel="${OPTARG}" ;;
        h) host_config="${OPTARG}" ;;
        o) os_config="${OPTARG}" ;;
        t) target_host=${OPTARG} ;;
        H) target_home=${OPTARG} ;;

        K) keep_dist_at_target=1 ;;

        e) enter=1 ;;
        E) enter=2 ;;

        f) fa_dist=${OPTARG}; dist_keep=1 ;;

        ?) echo "Bad option -${OPTARG}"; exit 1;
    esac; } || {
        params+=("${!OPTIND}"); ((OPTIND++))
    }
done

if [[ ${#params[@]} -lt 1 ]]; then
    error "$0 <config> [<action>]"
fi

config="${params[0]}"
action=${params[1]}

[[ -z $action ]] && action=reinstall

fa_action="$DIR/action/$action.ssh"
[[ ! -f "$fa_action" ]] && error "File: [$fa_action] not exists!"

IFS=':' read -a cfg_arr <<< "$(bobash-node "$config")"

[[ -z $channel     ]] && channel="${cfg_arr[1]}"
[[ -z $host_config ]] && host_config="${cfg_arr[3]}"

[[ -z $target_home ]] && target_home="${cfg_arr[4]}"
[[ -z $target_home ]] && target_home='~/.config/user/bob'

[[ -z $target_host ]] && target_host="$config"

if [[ "$action" != 'prepare' && "$action" != 'uninstall' ]]; then
    build_pack=1
fi

if [[ "$action" != 'pack' ]]; then
    deploy_pack=1
fi

os_config="$(get-target-os)"

config-os-exists   "$os_config"   || os_config=
config-host-exists "$host_config" || host_config=

if [[ $file_only -gt 0 && -z $fa_dist ]]; then
    fa_dist="${os_config:-no-os}_${host_config:-no-host}"
    dist_keep=1
fi

if [[ $channel == ssh || $channel == fs ]]; then
    build_opts+=(-d)
fi

# Config --------------------------------------------------------------------

[[ -n $debug ]] && {
echo -e "
-- Configuration --------------------------------------------------------------
root  : ($([[ -d $ROOT_DIR ]] && echo 'exists' || echo 'NOT exists')) $ROOT_DIR
deploy: ($([[ -d $DIR      ]] && echo 'exists' || echo 'NOT exists')) $DIR
files : ($([[ -d $da_files ]] && echo 'exists' || echo 'NOT exists')) $da_files
-------------------------------------------------------------------------------"
}

if [[ $enter -lt 2 ]]; then
    if [[ -z $fa_dist ]]; then
        dist_label="build : ${os_config:-None}/${host_config:-None}"

        if [[ $file_only -gt 0 ]]; then
            dist_label="$dist_label [IMPOSSIBLE] - file only"
        fi
    else
        dist_label="file  : $fa_dist"
    fi

    echo -e "
-- Bobash deploying -------------------------------------
config: $config
target: $target_host:$target_home [$channel]
action: $action
$dist_label
---------------------------------------------------------
"

    if [[ -n $debug ]]; then
    echo -e "
-- Action -----------------------------------------------
$(cat-action "$action")
---------------------------------------------------------
"
    fi

fi

[[ -n $debug ]] && exit

[[ -z $channel ]] && error "No channel is set"

if [[ $file_only -gt 0 && -z $fa_dist ]]; then
    error "You can deploy only already built dist files"
fi

if [[ -n $fa_dist ]]; then
    if [[ ! -f $fa_dist ]]; then
        declare file=$ROOT_DIR/build/bobash_${fa_dist}.tar.gz
        [[ -f $file ]] && fa_dist="$file"

        [[ ! -f $fa_dist ]] && error "Dist file [$fa_dist] does not exist!"
    fi
fi

fa_installer="$DIR/bobash-cfg.sh"
fa_prepare="$DIR/action/prepare.ssh"

deploy="deploy-${channel}"

# Operate --------------------------------------------------

# cd "$DIR"
# pwd

[[ -n $os_config ]] && build_opts+=(-o $os_config)
[[ -n $host_config ]] && build_opts+=(-h $host_config)

if [[ $enter -lt 2 && -z $fa_dist && $build_pack -gt 0 ]]; then
    fa_dist="$("$DIR/build.sh" "${build_opts[@]}")" || error "Cannot create build"
    chmod g+r "$fa_dist"
fi

chmod g+r "$fa_installer"

if [[ $deploy_pack -gt 0 ]]; then
	echo "-- Deploying to $target_host:$target_home [$channel] ------"
    $deploy

    echo '-- Deploying done --'
fi

onExit

echo
echo 'Done'
