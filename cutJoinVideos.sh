#######################################################
# Facade for cutVideos.sh and joinVideos.sh.
#######################################################

[ -z "$1" -o ! -d "$1" ] && {
	echo "SYNTAX: $0 videoDirectory" >&2
	echo "	Cuts videos according to cuts.txt, joins videos to videoDirectoryBasename.MP4." >&2
	exit 1
}

cutVideos.sh $1 || exit $?
joinVideos.sh $1 || exit $?
