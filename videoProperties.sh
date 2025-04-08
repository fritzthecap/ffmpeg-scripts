#######################################################
# Displays quality settings of video and audio.
#######################################################

[ -z "$1" -o -d "$1" ] &&    {
    echo "SYNTAX: $0 [-a|videoPropertyCsv] videoFile [videoFile ...]" >&2
    echo "Shows significant properties of first video and audio stream." >&2
    echo "-a: show full property listing" >&2
    echo "videoPropertyCsv: comma-separated list of video properties to show" >&2
    exit 1
}

formatProperties()    {	# $1 = properties CSV, $2 = video file
    ffprobe -v error \
            -show_entries format=$1 \
            -of default=noprint_wrappers=1 $2 \
        | sort \
        | uniq \
        | sed 's/^/format /'
}

streamProperties()    {	# $1 = properties CSV, $2 = stream of property, $3 = video file
    ffprobe -v error \
            -select_streams $2 -show_entries stream=$1 \
            -of default=noprint_wrappers=1 $3 \
        | sort \
        | uniq \
        | sed 's/^/'$2' /'
}

displayVideoProperties()	{	# $1 = video file
    videoFile=$1
    echo "Properties for $videoFile" >&2
    
    if [ -n "$propertyList" ]
    then
        streamProperties $propertyList v:0 $videoFile
    elif [ "$showAll" = "true" ]
    then
        ffprobe -v error -show_format -show_streams $videoFile
    else
        formatProperties format_name,bit_rate $videoFile
        streamProperties codec_name,profile,time_base,pix_fmt,avg_frame_rate,r_frame_rate,width,height,bit_rate v:0 $videoFile
        streamProperties codec_name,sample_rate,channels,bit_rate a:0 $videoFile
    fi
}

for argument in $*
do
    if [ -f "$argument" ]
    then
        displayVideoProperties $argument
    elif [ "$argument" = "-a" ]
    then
        showAll=true
    else
        propertyList=$argument
    fi
done
