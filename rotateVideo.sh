
method=$1
sourceVideo=$2

[ "$method" != "-m" -a "$method" != "-r" -o -z "$sourceVideo" ] && {
	echo "SYNTAX: $0 -m|-r videofile" >&2
	echo "	-m: rotate by removing rotation from metadata (fast)" >&2
	echo "	-r: rotate by re-encoding (slow)" >&2
	echo "If videofile is xxx.mp4, the result file will be xxx_rotated.mp4." >&2
	echo "Try out -m first, because mostly this is enough." >&2
	echo "With -r, maybe you need to remove rotation from metadata before in some cases." >&2
	echo "With -r, please edit this script and set your desired 'transpose' parameter," >&2
	echo "	preset is 90 degrees counterclockwise (transpose=2), edit line 40 for other values." >&2
	exit 1
}
[ -f "$sourceVideo" ] || {
	echo "Not a file: $sourceVideo" >&2
	exit 2
}

sourceDir=`dirname \$sourceVideo`
sourceFile=`basename \$sourceVideo`
filename=${sourceFile%.*}	# filename without extension
extension=${sourceFile#*.}	# extension without filename
targetVideo=$sourceDir/${filename}_rotated.$extension

echo "Rotating $sourceVideo to $targetVideo" >&2
	
if [ $method = "-m" ]	# edit metadata
then
	echo "... by removing video rotation in metadata ..." >&2
	ffmpeg -v error -y -i $sourceVideo -c copy -metadata:s:v:0 rotate=0 $targetVideo || exit 2
else
	# re-encode
	#    0 = Rotate 90 deg. counterclockwise and do a vertical flip (default)
	#    1 = Rotate 90 deg. clockwise
	#    2 = Rotate 90 deg. counterclockwise
	#    3 = Rotate 90 deg. clockwise and do a vertical flip
	#    Rotate 180 degrees clockwise: transpose="transpose=1,transpose=1" = several actions in one command
	transpose="transpose=1"
	
	# keep time_base
	getInverseTimeBase()	{	# $1 = video file path
		ffprobe -v error -select_streams v:0 -show_entries stream=time_base -of default=noprint_wrappers=1 $1 | sed 's/time_base=1\///'
	}
	inverseTimeBase=`getInverseTimeBase \$sourceVideo`
	echo "Source inverse time_base: $inverseTimeBase" >&2
	keepTimeBase="-vsync 0 -enc_time_base -1 -video_track_timescale $inverseTimeBase"
	
	echo "... by re-encoding ..." >&2
	ffmpeg -v error -y -i $sourceVideo -vf "$transpose" $keepTimeBase $targetVideo || exit 3
	
	echo "Target inverse time_base: `getInverseTimeBase \$targetVideo`" >&2
fi

echo "Created $targetVideo"
