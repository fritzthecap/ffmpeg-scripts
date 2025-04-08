##############################
# create a video from an image
##############################

frameRate=30/1
pixelFormat=yuv420p
inverseTimeBase=90000
keepTimeBase="-video_track_timescale $inverseTimeBase"
audioCodec=aac
audioSampleRate=48000

currentDir=`pwd`
cd `dirname \$0`	# change to where this script resides
PATH=$PATH:`pwd`	# take sibling scripts into path
cd $currentDir

syntax() {
	echo "SYNTAX: $0 imagefile [widthxheight [seconds]]" >&2
	echo "	Creates a video from an image." >&2
	echo "	widthxheight: image target dimension, default is 2336x1080" >&2
	echo "	seconds: the video duration, default is 4 seconds" >&2
	exit 1
}

[ -f "$1" ] || {
	echo "File not found: $1" >&2
	exit 2
}

imageFile="$1"
widthxheight=${2:-2336x1080}
videoSeconds=${3:-4}
videoFile="${imageFile%.*}".MP4	# filename without extension

rm -f $videoFile 2>/dev/null

scaledImageFile="`dirname \$imageFile`/scaled_`basename \$imageFile`"
imageToSize.sh "$imageFile" "$scaledImageFile" $widthxheight || exit 3

tmpVideoFile="`dirname \$videoFile`/tmp_`basename \$videoFile`"

cleanup()	{
	rm -f $scaledImageFile $tmpVideoFile
}
error()	{
	cleanup
	exit $1
}

echo "Creating a $videoSeconds seconds video from image ..." >&2
ffmpeg -y -v error -loop 1 \
	-i "$scaledImageFile" -c:v libx264 \
	-t $videoSeconds \
	-pix_fmt $pixelFormat -r $frameRate $keepTimeBase "$tmpVideoFile" || error $?

echo "Adding a silent audio track ..." >&2
ffmpeg -v error -y \
	-f lavfi -i anullsrc=sample_rate=$audioSampleRate:channel_layout=stereo \
	-i $tmpVideoFile \
	-c:v copy -c:a $audioCodec \
	-shortest "$videoFile" || error $?
	
cleanup
		
echo "Created $videoFile"
