#######################################################
# Extracts an image from given video at given time.
#######################################################

IMAGEFILENAME=image.png

[ -z "$1" -o ! -f "$1" -o -z "$2" ] &&    {
    echo "SYNTAX: $0 videoFile time [imagePathFile]" >&2
    echo "	Extracts an image from a video to an image file." >&2
    echo "	Example:" >&2
    echo "		$0 myvideo.mp4 1:23" >&2
    echo "	would extract the key-frame image at or before minute 1 second 23" >&2
    echo "	from myvideo.mp4 to $IMAGEFILENAME in directory where myvideo.mp4 resides" >&2
    exit 1
}

video=$1
time=$2

[ -f "$video" ] || {
	echo "No such file: $video" >&2
	exit 1
}

videoDirectory=`dirname \$video`	# resolves to "." when no path on file

if [ -z "$3" ]
then
	image=$videoDirectory/$IMAGEFILENAME
else
	imageDirectory=`dirname \$3`
	
	if [ $imageDirectory -eq "." ]
	then
		image=$videoDirectory/$3
	else
		image=$3
	fi
fi

echo "Creating $image ..." >&2
	
ffmpeg -y -v error \
	-ss $time -i $video -frames:v 1 \
	-f image2 $image

if [ "$?" -eq 0 ]
then
	echo "Created $image" >&2
else
	echo "Error! Exitcode was $?" >&2
fi