#######################################################
# Joins together video clips created by cuts.sh.
#######################################################

checkCompatiblity="false"  # "true" when using different cameras!

[ -z "$1" ] && {
	echo "SYNTAX: $0 videoDir" >&2
	echo "	Joins all _CUT.MP4 videos in given videoDir/cuts." >&2
	echo "	videoDir: directory of original videos where 'cuts' directory is below." >&2
	exit 1
}

[ -d "$1" ] || {
	echo "Given videoDir is not a directory: $1" >&2
}

cd $1/cuts || exit 2	# "cuts" is a naming convention used in cutVideos.sh

allCutsVideo=$1/`basename \$1`.MP4
echo "Creating $allCutsVideo ..." >&2

concatFile=concat.txt
rm -f $concatFile

formatProperties()	{	# $1 = property name, $2 = video file path
	ffprobe -v error -show_entries format=$1 -of default=noprint_wrappers=1 $2 | sort | uniq | sed 's/^/format /'
}

streamProperties()	{	# $1 = property name, $2 = stream name, $3 = video file path
	ffprobe -v error -select_streams $2 -show_entries stream=$1 -of default=noprint_wrappers=1 $3 | sort | uniq | sed 's/^/'$2' /'
}

cleanup()	{
	rm -f ffprobe1.check ffprobe2.check $concatFile
}

error()	{	# message, exitcode
	echo $1 >&2
	cleanup
	exit $2
}

cleanup

# remove preceding result video
[ -f $allCutsVideo ] && {
	echo "Removing existing join-video $allCutsVideo ..." >&2
	rm -f $allCutsVideo || exit 4
}

for videoClip in `ls -1 *_CUT.MP4* | sort`	# naming convention used in cutVideos.sh
do
	case $videoClip in
		*.MP4TS)
			[ "$mpegts" = "false" ] && error "Can not mix .MP4 and .MP4TS files: $videoClip" 6
			mpegts=true
			;;
		*.MP4)
			[ "$mpegts" = "true" ] && error "Can not mix .MP4TS and .MP4 files: $videoClip" 7
			mpegts=false
			;;
	esac
	
	[ "$mpegts" = "false" -a "$checkCompatiblity" = "true" ] &&	{	# check if different video properties
		echo "Compatibility check: $videoClip ..."
	
		if [ -f ffprobe1.check ]
		then
			checkfile=ffprobe2.check
		else
			checkfile=ffprobe1.check
			firstClip=$videoClip
		fi
		
		formatProperties format_name $videoClip >$checkfile
		streamProperties codec_name,profile,time_base,pix_fmt,r_frame_rate,width,height v:0 $videoClip >>$checkfile
		streamProperties codec_name,sample_rate,channels a:0 $videoClip >>$checkfile
		
		[ -f ffprobe2.check ] && 	{	# being at second file
			diff ffprobe1.check ffprobe2.check || error "The video $firstClip (left) seems not to be combinable with $videoClip (right)!" 8
		}
	}
	
	echo "file $videoClip" >>$concatFile
done

[ -f $concatFile ] || error "No *_CUT.MP4* files found in given directory: $1" 9
cat $concatFile

# concatenate the videos
[ "$mpegts" = "true" ] && fromMpegTs="-bsf:a aac_adtstoasc -brand avc1 -f 3gp"
echo "Concatenating videos ..."

ffmpeg -v error -y -f concat -i $concatFile -c copy $fromMpegTs $allCutsVideo

cleanup
echo "Generated $allCutsVideo"
