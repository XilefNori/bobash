# echo "loading ${BASH_SOURCE[0]} ..." >&2

# To pick up the latest recommended .bash_profile content,
# look in /etc/defaults/etc/skel/.bash_profile

# ~/.bash_profile: executed by bash for login shells.

# echo "Source of loading"; for i in ${BASH_SOURCE[@]}; do echo "$i"; done

declare load_path=''
for i in ${BASH_SOURCE[@]:1:2}; do
	load_path="$load_path -> $i"
done

[[ -n $BABUN_LOADED ]] && {
	echo "Skipping [${BASH_SOURCE[0]}$load_path] - babun"
	return
}

for i in ${BASH_SOURCE[@]}; do
	[[ $i =~ /babun.bash ]] && {
		echo "Skipping [${BASH_SOURCE[0]}$load_path] - babun"
		BABUN_LOADED=1

		return
	}
done

echo "Loading [${BASH_SOURCE[0]}$load_path]"

# source the system wide bashrc if it exists
if [ -e /etc/bash.bashrc ] ; then
  source /etc/bash.bashrc
fi

SRC="${BASH_SOURCE[0]//\\//}"
DIR="$(cd -P "${SRC%/*}" > /dev/null && pwd)"

# source the users bashrc if it exists
if [ -e "${DIR}/.bashrc" ] ; then
  source "${DIR}/.bashrc"
else
  echo "${DIR}/.bashrc not found" >&2
fi


# export DISPLAY=localhost:0.0
