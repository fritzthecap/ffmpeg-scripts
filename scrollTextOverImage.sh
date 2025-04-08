###################################################
# Creates a video where text scrolls over an image.
###################################################

syntax() {
	echo "SYNTAX: $0 imageFile textFile videoFile" >&2
	echo "	Scrolls text over image, result is a video." >&2
	exit 1
}

imageFile="$1"
textFile="$2"
videoFile="$3"

[ -f "$imageFile" -a -f "$textFile" ] || syntax
[ -z "$videoFile" ] && syntax

# calculate duration of video by number of text lines
numberOfLines=`wc -l <"\$textFile"`

videoSeconds=`awk 'BEGIN { print 12 + ('\$numberOfLines' + 1) * 1.5 }'`
# videoSeconds=`awk 'BEGIN { print 8 + ('\$numberOfLines' + 1) }'`

echo "Generating $videoFile that scrolls $textFile over $imageFile, lasting $videoSeconds seconds ...." >&2

# escape percent sign, it would make ffmpeg fail
rm -f replaced.txt
sed 's/%/\\%/g' <$textFile >replaced.txt

ffmpeg -y -v error -loop 1 \
	-i "$imageFile" \
	-vf drawtext="\
		fontsize = 70:\
		fontcolor = white:\
		borderw = 7:\
		bordercolor = black:\
		line_spacing = 60:\
		textfile = \'replaced.txt\':\
		x = (w - text_w) / 2:\
		y = h - 80 * t" \
	-t $videoSeconds "$videoFile"

##################
# videoSeconds=`awk 'BEGIN { print 12 + ('\$numberOfLines' + 1) * 1.5 }'`
# fast: 
# line_spacing = 50
# y = h - 120 * t
##################
# videoSeconds=`awk 'BEGIN { print 12 + ('\$numberOfLines' + 1) * 1.5 }'`
# slow:
# line_spacing = 60
# y = h - 80 * t
##################

rm -f replaced.txt
