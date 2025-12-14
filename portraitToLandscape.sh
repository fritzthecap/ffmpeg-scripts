
defaultScale=1920:1080

[ -z "$1" ] && {
	echo "SYNTAX: $0 video" >&2
	echo "	Converts given video XXX.mp4 from portrait to landscape" >&2
	echo "	Result video will be XXX_landscape.mp4" >&2
	echo "	Default scale is $defaultScale, please edit script when not sufficient!" >&2
	exit 1
}

sourceVideo="$1"
echo "Converting $sourceVideo to landscape ..." >&2

sourceDir=`dirname \$sourceVideo`
sourceFile=`basename \$sourceVideo`

filename=${sourceFile%.*}	# filename without extension
extension=${sourceFile#*.}	# extension without filename

targetVideo=$sourceDir/${filename}_landscape.$extension

ffmpeg -v error -y -i ${sourceVideo} \
	-vf "scale=$defaultScale:force_original_aspect_ratio=decrease,pad=$defaultScale:-1:-1:color=black" \
	$targetVideo

echo "Generated $targetVideo" >&2
