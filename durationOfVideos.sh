#######################################################
# The rounded duration of all videos in given directory.
#######################################################

[ -z "$1" ] && {
    echo "SYNTAX: $0 videoDir" >&2
    exit 1
}

cd $1 || exit 2

sum=0
for video in `ls -1 *.MP4 *.mp4 2>/dev/null | sort`
do
    seconds=`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 \$video`
    sum=`echo "\$sum \$seconds" | awk '{ print $1 + $2 }'`
    
    echo "$video: $seconds seconds" >&2
done

echo "sum of seconds = $sum" >&2

rounded=`echo \$sum | awk '{ print int($1 + 0.5) }'`
    
hours=`expr \$rounded / 3600`
rest=`expr \$rounded % 3600`
minutes=`expr \$rest / 60`
seconds=`expr \$rest % 60`

echo "$hours:$minutes:$seconds"
