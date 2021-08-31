#!/usr/bin/env bash

# Init ----------------------------------------------------------------

SRC="${BASH_SOURCE[0]//\\//}"
[[ -z "$SRC" ]] && SRC="$(readlink -f $0)"
DIR="$(cd -P "${SRC%/*}" > /dev/null && pwd)"

ROOT_DIR="$(cd $DIR/.. > /dev/null && pwd)"

# Config --------------------------------------------------------------

if [[ -d "$ROOT_DIR/files" ]]; then
    da_files="$ROOT_DIR/files"
else
    da_files="$ROOT_DIR"
fi

# Utils ---------------------------------------------------------------

error() { echo "ERROR: $@" >&2;  exit 1; }

copy-files() {
    declare da_src="$1"
    declare da_dst="$2"

    [[ ! -d "$da_src" ]] && error "No source dir [$da_src]"
    [[ ! -d "$da_dst" ]] && mkdir -p "$da_dst"

    cp -rt "$da_dst" "$da_src"
}

{

# Arguments -----------------------------------------------------------

declare debug os host deploy da_dist

# -- Arguments --
declare flags="do:h:D:" OPTIND=1
declare -a params
for (( ; OPTIND <= $#; )) do
    getopts "$flags" flag && { case $flag in
        d) deploy=1 ;;
        o) os="${OPTARG}"      ;;
        h) host="${OPTARG}"    ;;
        D) da_dist="${OPTARG}" ;;
    esac; } || {
        params+=("${!OPTIND}"); ((OPTIND++))
    }
done

# Operate --------------------------------------------------

[[ -z $da_dist ]] && da_dist="$ROOT_DIR/build"

echo "
-- Building bobash dist -------------------------
os   : ${os:-None}
host : ${host:-None}"

[[ -n $os   && ! -d "$da_files/os/$os"     ]] && error "no os files: [$os]"
[[ -n $host && ! -d "$da_files/host/$host" ]] && error "no host files: [$host]"

name="bobash_${os:-no-os}_${host:-no-host}"

fa_tar="$da_dist/$name.tar"
fa_dist="${fa_tar}.gz"

echo "dist : $fa_dist"

da_dist_files="$da_dist/dist"

cd "$DIR"

[[ -d "$da_dist_files" ]] && rm -rf "$da_dist_files"

mkdir -p "$da_dist_files"

declare -a items

# General config
items+=("$da_files/bin/")
items+=("$da_files/etc/")
items+=("$da_files/ext/")
items+=("$da_files/install/")
items+=("$da_files/lib/")
items+=("$da_files/local/")
items+=("$da_files/pack/")
items+=("$da_files/sys/")
items+=("$da_files/rc/")

if [[ -n $deploy ]]; then
    items+=("$ROOT_DIR/deploy")
    items+=("$ROOT_DIR/docker")
fi

declare list=()
for item in "${items[@]}"; do
    [[ ! -e $item ]] && { echo "Skipping item [$item]!"; continue; }

    list+=($item)
done

cp -rt "$da_dist_files" "${list[@]}"

mkdir "$da_dist_files/build"

# OS specific config
if [[ -n $os ]]; then
    copy-files "$da_files/os/$os" "$da_dist_files/os" || exit 1
fi

# Host specific config
if [[ -n $host ]]; then
    copy-files "$da_files/host/$host" "$da_dist_files/host" || exit 1
fi

echo "Running processors ..."
processors=($(find "$DIR" -name "build-*.sh"))
for proc in "${processors[@]}"; do
    echo "Processor [$(basename "$proc")]"
    bash "$proc" "$da_dist_files" || { echo "Processor [$(basename "$proc")] broken!"; exit 1; }
done

# Making archive
echo "Preparing archive ..."

echo tar -cf "$fa_tar" -C "$da_dist_files" .

tar -cf "$fa_tar" -C "$da_dist_files" .
gzip -f -9 "$fa_tar"

# tar -rf "$fa_archive" --transform "s:host/$target_host:host:" -C "$ROOT_DIR" host/$target_host


find "$fa_dist" -maxdepth 1 -printf '%CY-%Cm-%Cd [%CH:%CM]\t%s\t%f\n' &&
rm -rf "$da_dist_files"

echo '-------------------------------------------------
'

} >&2

echo "$fa_dist"
