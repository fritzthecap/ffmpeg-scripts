#######################################################
# Lists video file names into cutting plan cuts.txt.
#######################################################

[ -z "$1" ] && {
	echo "SYNTAX: $0 videoDir" >&2
	echo "	Lists video files.MP4 into cutting plan cuts.txt." >&2
	exit 1
}

cd $1 || exit 1

cutsText=cuts.txt
[ -f $cutsText ] &&	{	# do not overwrite manually edited one
	echo "ERROR: $1/$cutsText already exists!" >&2
	exit 1
}

ls -1 *.MP4 *.mp4 2>/dev/null | sort >$cutsText

echo "Generated $cutsText video list in `pwd`"
