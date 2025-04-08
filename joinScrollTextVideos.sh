#################################################
# create and join videos where texts scroll over images
#################################################

allCutsVideo=ALLCUTS.MP4
imageExtension=png

currentDir=`pwd`
cd `dirname \$0`	# change to where this script resides
PATH=$PATH:`pwd`	# take sibling scripts into path
cd $currentDir

syntax() {
	echo "SYNTAX: $0 directory [widthxheight]" >&2
	echo "	Creates and joins videos where texts scroll over images." >&2
	echo "	Text- and image-files have same name but different extensions: .txt -> .$imageExtension" >&2
	echo "	directory: the folder where text and image files are" >&2
	echo "	widthxheight: image target dimension, default is 1920x1080" >&2
	echo "	CAUTION: file names must not contain spaces or any kind of quotes!" >&2
	exit 1
}

[ -d "$1" ] || syntax
widthxheight=$2

cd $1

concatFile=concat.txt
rm -f $concatFile 2>/dev/null

for textFile in `ls -1 *.txt | sort`
do
	echo "Checking $textFile for associated image ...." >&2
	baseName=`basename "\$textFile" .txt`
	imageFile="$baseName.$imageExtension"
	
	[ -f "$imageFile" ] && {	# when there is an associated image for text
		echo "Found $imageFile ...." >&2
		
		scaledImageFile="scaled_$imageFile"
		imageToSize.sh "$imageFile" "$scaledImageFile" $widthxheight || exit 2
		
		videoFile="$baseName.MP4"
		scrollTextOverImage.sh "$scaledImageFile" "$textFile" "$videoFile" || exit 3
		
		rm -f "$scaledImageFile"
		
		echo "file $videoFile" >>$concatFile
	}
done

[ -f $concatFile ] || {
	echo "Found no associated .txt and .$imageExtension files in `pwd`" >&2
	exit 4
}

echo "Joining videos ...." >&2
ffmpeg -v error -y -f concat -i $concatFile -c copy $allCutsVideo

for cut in `cat \$concatFile`
do
	case "$cut" in
		file)	;;
		*)	rm -f "$cut" ;;
	esac
done

rm -f $concatFile

echo "Done." >&2
