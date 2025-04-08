#######################################################
# Extracts an image from given video at given time.
#######################################################

IMAGEFILENAME=image.png

[ -z "$1" -o ! -f "$1" -o -z "$2" ] &&    {
    echo "SYNTAX: $0 videoFile time [imageFilePath]" >&2
    echo "Extracts an image from a video to default image file $IMAGEFILENAME" >&2
    echo "Example:" >&2
    echo "	$0 myvideo.mp4 1:23 title-image.png" >&2
    echo "	would extract the key-frame image at or before minute 1 second 23" >&2
    echo "	from myvideo.mp4 to title-image.png." >&2
    exit 1
}

video=$1
time=$2
image=${3:-$IMAGEFILENAME}

ffmpeg -y \
	-ss $time -i $video -frames:v 1 \
	-f image2 $image
