####################################################
# Scales an image to a fixed size using ImageMagick.
####################################################

# defaultDimension=1920x1440
defaultDimension=1920x1080	# standard video dimension
edgeColor=black

syntax()	{
	echo "SYNTAX: $0 sourceImageFile targetImageFile [widthxheight]" >&2
	echo "	Scales an image to width x height, keeping aspect ratio, adding edges." >&2
	echo "	sourceImageFile: the image to scale" >&2
	echo "	targetImageFile: the result image file" >&2
	echo "	widthxheight: optional target dimension, default is $defaultDimension" >&2
	exit 1
}

[ -f "$1" -a -n "$2" ] || syntax
sourceImageFile="$1"
targetImageFile="$2"
dimension=${3:-$defaultDimension}	

echo "Scaling to $dimension from $sourceImageFile to $targetImageFile ..." >&2

# call ImageMagick
convert "$sourceImageFile" \
	-resize $dimension \
	-gravity center \
	-background $edgeColor \
	-extent $dimension \
	"$targetImageFile"
