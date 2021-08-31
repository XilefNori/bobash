#!/usr/bin/env bash

# Init -------------------------------------------------------------

SRC="${BASH_SOURCE[0]//\\//}"
[[ -z "$SRC" ]] && SRC="$(readlink -f $0)"
DIR="$(cd -P "${SRC%/*}" > /dev/null && pwd)"

ROOT_DIR="$(cd $DIR/.. > /dev/null && pwd)"

# Functions -----------------------------------------------------------------------

error() { echo "$@" >&2;  exit 1; }

# Args ----------------------------------------------------------------------------

declare run

# -- Arguments --
declare flags="rR" OPTIND=1
declare -a params
for (( ; OPTIND <= $#; )) do
    if getopts "$flags" flag; then case $flag in
          r|R) run=1 ;;
    esac; else
        params+=("${!OPTIND}"); ((OPTIND++))
    fi
done

# Run ------------------------------------------------------------------------------

fa_dist="$1"
fa_dist="${fa_dist/\~/$HOME}"
fa_dist_use="$DIR/dist/bobash.tar.gz"

if [[ -n $fa_dist ]]; then
    if [[ ! -f $fa_dist ]]; then
        [[ -f $ROOT_DIR/build/$fa_dist ]] && fa_dist="$ROOT_DIR/build/$fa_dist"
        [[ -f $DIR/dist/$fa_dist       ]] && fa_dist="$DIR/dist/$fa_dist"

        [[ ! -f $fa_dist ]] && error "Dist file [$fa_dist] does not exist!"
    fi

	cp -f "$fa_dist" "$fa_dist_use"
fi

[[ ! -f $fa_dist_use ]] && error "No dist file [$fa_dist_use] exists!"

cd "$DIR"

cp -f "$ROOT_DIR/deploy/bobash-cfg.sh" "$DIR/scripts"

make docker/Dockerfile.php || error "Cannot build [docker/Dockerfile.php]"

docker volume create --name=bobash-rc

build_opts=(
    --build-arg DEVELOPER_UID="$(id -u)"
    --build-arg DEVELOPER_GID="$(id -g)"
)

docker-compose -f docker-compose.yml build "${build_opts[@]}"
docker-compose -f docker-compose.yml up

[[ -f "$fa_dist_use" ]] && rm -f "$fa_dist_use"

if [[ -n $run ]]; then
    docker run -v bobash-rc:/bobash/home -u developer -it bobash bash -c 'HOME=/bobash/home bash'
fi
