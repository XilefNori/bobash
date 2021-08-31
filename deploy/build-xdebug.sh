bb_module msg -q || exit 1

da_build="$1"
files=($(find "$da_build" -name _xdebug.in))

if [[ ${#files[@]} -eq 0 ]]; then
	exit
fi

echo "Found ${#files[@]} _xdebug.in files"

if [[ -z $XDEBUG_REMOTE_CONFIG ]]; then
	echo "No XDEBUG_REMOTE_CONFIG is set!"

	exit
fi


echo "${files[@]}" | xargs sed -i "s:%XDEBUG_REMOTE_CONFIG%:$XDEBUG_REMOTE_CONFIG:"
