brighter=0.2    # 20% brighter
sourceVideo=$1

[ -z "$sourceVideo" ] && {
    echo "SYNTAX: $0 videofile [brightnessIncrement]" >&2
    echo "    Brighten or darken a video, default brightnessIncrement is 0.2 for 20% brighter, -0.1 for 10% darker" >&2
    echo "    If videofile is xxx.mp4, the result file will be xxx_brighter.mp4" >&2
    exit 1
}
[ -f "$sourceVideo" ] || {
    echo "Not a file: $sourceVideo" >&2
    exit 2
}

[ -n "$2" ] && {
    brighter=$2
}

sourceDir=`dirname \$sourceVideo`
sourceFile=`basename \$sourceVideo`
filename=${sourceFile%.*}    # filename without extension
extension=${sourceFile#*.}    # extension without filename
targetVideo=$sourceDir/${filename}_brighter.$extension

# keep time_base
getInverseTimeBase()    {    # $1 = video file path
    ffprobe -v error -select_streams v:0 -show_entries stream=time_base -of default=noprint_wrappers=1 $1 | sed 's/time_base=1\///'
}
inverseTimeBase=`getInverseTimeBase \$sourceVideo`
keepTimeBase="-vsync 0 -enc_time_base -1 -video_track_timescale $inverseTimeBase"

echo "Changing brightness of $sourceVideo to $brighter ...." >&2

ffmpeg -v error -y -i $sourceVideo -vf eq=brightness=$brighter -c:a copy $keepTimeBase $targetVideo || exit 3

# contrast
# .... eq=brightness=$brighter:contrast=0.7 ....
# documented from -1000 to +1000, otherwise from -2.0 to +2.0, but below zero it inverts colors
# I assume from 0.0 to 2.0, whereby 1 is default (no change)

echo "Created $targetVideo"
