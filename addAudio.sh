#######################################################
# Adds audio to video.
#######################################################

fileMarker=audio

[ -z "$1" -o ! -f "$1" -o -z "$2" -o ! -f "$2" ] && {
	echo "SYNTAX: $0 videoFile audioFile" >&2
	echo "	Adds given audio track to given video, creating an xxx_$fileMarker.mp4 file." >&2
	exit 1
}

sourceVideo=$1
sourceDir=`dirname \$sourceVideo`
sourceFile=`basename \$sourceVideo`
filename=${sourceFile%.*}	# filename without extension
extension=${sourceFile#*.}	# extension without filename
targetVideo=$sourceDir/${filename}_$fileMarker.$extension

audio=$2

ffmpeg -v error -y -i $sourceVideo -i $audio -map 0:v -map 1:a -c:v copy -c:a copy $targetVideo

echo "Created $targetVideo"
