#######################################################
# Slow motion or time lapse for video.
#######################################################

fileMarker=timed

[ -z "$1" -o ! -f "$1" ] && {
	echo "SYNTAX: $0 videoFile [framesPerSecond]" >&2
	echo "	Slows down or speeds up given video, creating an xxx_$fileMarker.mp4 file." >&2
	echo "	framesPerSecond default is 15, which is half speed of normal 30 fps." >&2
	exit 1
}

sourceVideo=$1
sourceDir=`dirname \$sourceVideo`
sourceFile=`basename \$sourceVideo`
filename=${sourceFile%.*}	# filename without extension
extension=${sourceFile#*.}	# extension without filename
targetVideo=$sourceDir/${filename}_$fileMarker.$extension

framesPerSecond=15
[ -n "$2" ] && framesPerSecond=$2

tempRawFile=raw.h264

cleanup()	{
	rm -rf $tempRawFile
}
error()	{
	cleanup
	exit $1
}

# copy the video to a raw bitstream format
ffmpeg -v error -y -i $sourceVideo -map 0:v -c:v copy -bsf:v h264_mp4toannexb $tempRawFile || error 2

# generate new timestamps while muxing to a container
ffmpeg -v error -y -fflags +genpts -r $framesPerSecond -i $tempRawFile -c:v copy $targetVideo || error 3

cleanup

echo "Created $targetVideo"
