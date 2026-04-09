
defaultScale=2336:1080	# width:height
color=gray

[ -z "$1" ] && {
	echo "SYNTAX: $0 video [topCropPixels bottomCropPixels]" >&2
	echo "	Converts given video XXX.mp4 from portrait to landscape, adding gray borders" >&2
	echo "	Result video will be XXX_landscape.mp4" >&2
	echo "	Default scale is $defaultScale, please edit script when not sufficient!" >&2
	exit 1
}

sourceVideo="$1"

[ -f "$sourceVideo" ] || {
	echo "File not found: $sourceVideo" >&2
	exit 1
}

[ -n "$2" ] && {
	topCropPixels=$2
	bottomCropPixels=${3:-0}
	
	cropCommand="crop=iw:ih-$topCropPixels-$bottomCropPixels:0:$topCropPixels,"
}

sourceDir=`dirname \$sourceVideo`
sourceFile=`basename \$sourceVideo`

echo "Converting $sourceFile to landscape $defaultScale, in $sourceDir" >&2

filename=${sourceFile%.*}	# filename without extension
extension=${sourceFile#*.}	# extension without filename

targetVideo=$sourceDir/${filename}_landscape.$extension

ffmpeg -v error -y -i ${sourceVideo} \
	-vf "${cropCommand}\
		scale=$defaultScale:force_original_aspect_ratio=decrease,\
		pad=$defaultScale:-1:-1:color=$color" \
	-c:v libx264 -crf 23 \
	-c:a copy \
	${targetVideo}
	
# Left/right paddings by 'pad=width:height:x:y:color'
# default '-1:-1' centering could be replaced by '(ow-iw)/2:(oh-ih)/2'

echo "Generated $targetVideo" >&2

