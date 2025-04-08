#######################################################
# Creates a title for a video with text in file title.txt.
# Developed with ffmpeg 3.4.8-0ubuntu0.2.
#######################################################

# configurations

fontcolor=white	# foreground color
#fontsize=100	# size of text
bordercolor=black	# text outline color
boxbordercolor=Silver@0.6	# rectangle color, light gray, 60% opaque
boxborderwidth=40

videoFadeInDuration=1	# seconds
titleFadeDuration=1	# for both fade-in and -out
titleVisibility=4	# without fades
startTitleFadeIn=$videoFadeInDuration	# start title fade-in immediately after video fade-in

titleVideo=TITLE.MP4	# file name of the resulting title video, naming convention used by cutVideos.sh

# argument scanning

[ -z "$1" ] && {
	echo "SYNTAX: $0 videoDir/[TITLEVIDEO.MP4] [startSecond [titleTextFile]]" >&2
	echo "	Creates videoDir/$titleVideo with background image from video in given directory." >&2
	echo "	If TITLEVIDEO.MP4 is not given on commandline, it will be taken from videoDir/cuts.txt by default." >&2
	echo "	The title text is in file title.txt, or in titleTextFile, must be where the videos are." >&2
	echo "	Parameter startSecond only works when video file is given." >&2
	exit 1
}

if [ -d $1 ]	# get start-video and -time from cutting-plan
then
	cd $1 || exit 2
	cuttingPlan=cuts.txt
	[ -f $cuttingPlan ] || {
		echo "No cutting-plan cuts.txt found in `pwd`"
		exit 3
	}
	
	# get first video from cutting-plan, same regexp as in cutVideos.sh
	variableSettingScript=`awk '
		BEGIN	{ IGNORECASE = 1; }	# make all pattern matching case-insensitive
		/^[a-zA-Z0-9_\-]+\.MP4[ \t]*$/	{	# first video file
			videoFile = $1
		}
		/^[0-9]+:?[0-9]* /	{	# first start time
			if (videoFile) {	# print shell script
				print "firstVideo=" videoFile "; startTime=" $1
				exit 0
			}
		}
	' \$cuttingPlan`

	eval "$variableSettingScript"	# evaluate shell script printed by awk

	[ -f "$firstVideo" ] ||	{
		echo "Found no video $firstVideo in `pwd`" >&2
		exit 4
	}
elif [ -f $1 ]
then
	cd `dirname \$1` || exit 2
	firstVideo=`basename \$1`
	startTime=${2:-0}
else
	echo "Given title-video or its directory does not exist: $1" >&2
	exit 5
fi

titleText=${3:-title.txt}
[ -f $titleText ] || {
	echo "Found no title file $titleText in `pwd`" >&2
	exit 6
}

# fetch video target properties from first video

echo "Working in `pwd` ..."

streamProperty()	{	# $1 = property name, $2 = stream name, $3 = video file
	ffprobe -v error -select_streams $2 -show_entries stream=$1 -of default=noprint_wrappers=1:nokey=1 $3
}

getInverseTimeBase()    {    # $1 = video path
    echo `streamProperty time_base v:0 \$1` | sed 's/^1\///'
}

outputVideoProperties()	{	# $1 = video path
	echo "$1:\n  frameRate=`streamProperty r_frame_rate v:0 \$1`\n  pixelFormat=`streamProperty pix_fmt v:0 \$1`\n  timeBase=`streamProperty time_base v:0 \$1`"
}

getVideoAndAudioProperties()	{	# $1 = video file
	stream=v:0	# first found video
	
	frameRate=`streamProperty r_frame_rate \$stream \$1`
	pixelFormat=`streamProperty pix_fmt \$stream \$1`
	timeBase=`streamProperty time_base \$stream \$1`
	
	stream=a:0	#  first found audio
	audioCodec=`streamProperty codec_name \$stream \$1`
	audioSampleRate=`streamProperty sample_rate \$stream \$1`
}
getVideoAndAudioProperties $firstVideo

# start to work

firstImage=titleImage.jpg
fadeVideo=fadeVideo.mp4
cleanup()	{
	rm -f $fadeVideo
}
error()	{
	cleanup
	exit $1
}

echo "Extracting image at $startTime from $firstVideo as title background $firstImage ..."
ffmpeg -y -v error \
	-ss $startTime -i $firstVideo -frames:v 1 \
	-f image2 $firstImage || error $?

startTitleFadeOut=`echo "\$startTitleFadeIn \$titleFadeDuration \$titleVisibility" | awk '{ print $1 + $2 + $3 }'`
duration=`echo "\$startTitleFadeOut \$titleFadeDuration" | awk '{ print $1 + $2 }'`

# keep time_base
inverseTimeBase=`getInverseTimeBase \$firstVideo`
keepTimeBase="-video_track_timescale $inverseTimeBase"

outputVideoProperties $firstVideo

echo "Creating faded-in $titleVideo of $duration seconds with title from $titleText ... inverseTimeBase=$inverseTimeBase"
ffmpeg -y -v error \
	-loop 1 -i $firstImage -c:v libx264 -t $duration \
	-filter_complex "\
		[0]split[imagevideo][text];\
		[imagevideo]fade=t=in:st=0:d=$videoFadeInDuration[fadedvideo];\
		[text]drawtext=
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

outputVideoProperties $fadeVideo

echo "Adding a silent audio track to $titleVideo ..."
ffmpeg -v error -y \
	-f lavfi -i anullsrc=sample_rate=$audioSampleRate:channel_layout=stereo \
	-i $fadeVideo \
	-c:v copy -c:a $audioCodec \
	-shortest $titleVideo || error $?

cleanup

echo "Successfully created $titleVideo in `pwd`"

outputVideoProperties $titleVideo
