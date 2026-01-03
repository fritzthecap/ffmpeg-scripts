#######################################################
# Creates a title video from an image with text in file title.txt.
# Developed with ffmpeg 3.4.8-0ubuntu0.2.
#######################################################

# configurations

fontcolor=white	# foreground color
#fontsize=100	# size of text
bordercolor=black	# text outline color
boxbordercolor=Silver@0.6	# rectangle color, light gray, 40% opaque
boxborderwidth=40

videoFadeInDuration=1	# seconds
titleFadeDuration=1	# for both fade-in and -out
titleVisibility=4	# without fades
startTitleFadeIn=$videoFadeInDuration	# start title fade-in immediately after video fade-in

widthxheightDefault=2336x1080

# argument scanning

[ -z "$1" ] && {
	echo "SYNTAX: $0 videoDir/titleImageFile [widthxheight]" >&2
	echo "	Creates videoDir/$titleVideo with background image in given directory." >&2
	echo "	Dimension will be widthxheight, default is $widthxheightDefault." >&2
	echo "	The title-text must be in file title.txt." >&2
	exit 1
}

titleImage="$1"
[ -f "$titleImage" ] || {
	echo "Found no file named $titleImage" >&2
	exit 6
}

widthxheight=${2:-$widthxheightDefault}

scaledImageFile="`dirname \$titleImage`/scaled_`basename \$titleImage`"
imageToSize.sh "$titleImage" "$scaledImageFile" $widthxheight || exit 3
titleImage=$scaledImageFile

cd `dirname \$titleImage` || {
	echo "Could not change to directory of $titleImage" >&2
	exit 2
}
titleImage=`basename \$titleImage`

titleText=title.txt
[ -f $titleText ] || {
	echo "Found no $titleText file in `pwd`" >&2
	exit 6
}

titleVideo=TITLE.MP4

echo "Working in `pwd` ..."

frameRate=30/1
pixelFormat=yuv420p
audioCodec=aac
audioSampleRate=48000

# start to work

fadeVideo=fadeVideo.mp4

cleanup()	{
	rm -f $fadeVideo
}
error()	{
	cleanup
	exit $1
}

startTitleFadeOut=`echo "\$startTitleFadeIn \$titleFadeDuration \$titleVisibility" | awk '{ print $1 + $2 + $3 }'`
duration=`echo "\$startTitleFadeOut \$titleFadeDuration" | awk '{ print $1 + $2 }'`

inverseTimeBase=90000
keepTimeBase="-video_track_timescale $inverseTimeBase"

echo "Creating faded-in $titleVideo of $duration seconds with title from $titleText ..." >&2
ffmpeg -y -v error \
	-loop 1 -i $titleImage -c:v libx264 -t $duration \
	-filter_complex "\
		[0]split[imagevideo][text];\
		[imagevideo]fade=t=in:st=0:d=$videoFadeInDuration,pad=ceil(iw/2)*2:ceil(ih/2)*2[fadedvideo];\
		[text]drawtext=\
			textfile=$titleText:\
				fontcolor=$fontcolor:fontsize=h/10:borderw=7:bordercolor=$bordercolor:\
				line_spacing=60:\
				box=1:boxcolor=$boxbordercolor:boxborderw=$boxborderwidth:\
				x=(w-text_w)/2:y=(h-text_h)/2,\
			format=$pixelFormat,\
			fade=t=in:st=$startTitleFadeIn:d=$titleFadeDuration:alpha=1,\
			fade=t=out:st=$startTitleFadeOut:d=$titleFadeDuration:alpha=1[titletext];\
		[fadedvideo][titletext]overlay" \
	-pix_fmt $pixelFormat -r $frameRate $keepTimeBase $fadeVideo || error $?

echo "Adding a silent audio track to $titleVideo ..." >&2
ffmpeg -v error -y \
	-f lavfi -i anullsrc=sample_rate=$audioSampleRate:channel_layout=stereo \
	-i $fadeVideo \
	-c:v copy -c:a $audioCodec \
	-shortest $titleVideo || error $?

cleanup

echo "Successfully created $titleVideo in `pwd`" >&2
