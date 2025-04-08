#######################################################
# Removes audio from video.
#######################################################

fileMarker=noaudio

[ -z "$1" -o ! -f "$1" ] && {
	echo "SYNTAX: $0 videoFile" >&2
	echo "	Removes audio track(s) from given video, creating an xxx_$fileMarker.mp4 file." >&2
	exit 1
}

sourceVideo=$1
sourceDir=`dirname \$sourceVideo`
sourceFile=`basename \$sourceVideo`
filename=${sourceFile%.*}	# filename without extension
extension=${sourceFile#*.}	# extension without filename
targetVideo=$sourceDir/${filename}_$fileMarker.$extension

ffmpeg -v error -y -i $sourceVideo -an -c:v copy $targetVideo

echo "Created $targetVideo"
