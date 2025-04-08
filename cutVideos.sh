#######################################################
# Carries out a cutting plan containing several videos,
# each video can have a list of cuts.
#######################################################

which ffmpeg >/dev/null || {
	echo "You must have ffmpeg installed to cut videos with this script!" >&2
	exit 1
}

[ -z "$1" ] && {
	echo "SYNTAX: $0 videoDir/[cuts.txt] [-mpegts]" >&2
	echo "	All files.MP4 must be in same directory as cuts.txt is." >&2
	echo "	cuts.txt contains video names and start - end times of cuts below it." >&2
	echo "	Example:" >&2
	echo "		GOPR0123.MP4" >&2
	echo "		7 - 11" >&2
	echo "		0:59 - 1:2:34.5" >&2
	echo "		1:30 - end" >&2
	echo "		GOPR0456.MP4" >&2
	echo "		all" >&2
	echo "	Lines starting with spaces will be ignored." >&2
	echo "	'End' (end of video) and 'All' (whole video) are case-insensitive keywords." >&2
	echo "	Use -mpegts option when videos have different codecs, but mind that results are not .MP4 then, they are to be joined by joinVideos.sh!" >&2
	exit 2
}

if [ -d $1 ]	# assume default cuts.txt
then
	videoDir=$1
	cuttingPlan=cuts.txt
elif [ -f $1 ]	# explicitly named cutting plan
then
	videoDir=`dirname \$1`
	cuttingPlan=`basename \$1`
else
	echo "Could not find directory or file $1" >&2
	exit 3
fi

if [ "$2" = "-mpegts" ]	# write cuts in transport stream format for concat.sh
then
	mpegts=true	# this is needed when videos come from different sources
else
	mpegts=false
fi

cd $videoDir || exit 4

cutsDir=cuts

# remove all former clips
echo "Removing old cuts-directory $cutsDir in `pwd` ..." >&2
rm -rf $cutsDir || exit 5
mkdir $cutsDir || exit 5

# read the cutting plan and execute it
awk '
	BEGIN	{
		IGNORECASE = 1	# make all pattern matching case-insensitive
		toMpegTs = ("'$mpegts'" == "true")	# mpegts comes from underlying shell
		cutsDir = "'$cutsDir'"
		fileNr = 0
		
		if (exists("TITLE.MP4"))
			if (toMpegTs)	{	# must convert to transport-stream format
				videoFile = "TITLE.MP4"
				addCommand("0:0", "end")
			}
			else	# no need to cut title
				system("cp TITLE.MP4 " cutsDir "/000_TITLE_CUT.MP4")
	}
	
	function nextClipFile(fileNr)	{	# build the name "001_GOPR01234_CUT.MP4"
		videoClipFile = toupper(videoFile)
		sub(/\.MP4$/, "", videoClipFile)	# remove extension
		sortNumber = sprintf("%03i", fileNr)	# zero-padded sort number
		videoClipFile = sortNumber "_" videoClipFile "_CUT.MP4" (toMpegTs ? "TS" : "")
		
		return cutsDir "/" videoClipFile	# cutsDir comes from underlying shell
	}
	
	function addCommand(fromTime, toTime)	{
		if (toTime ~ /^end/)	 {
			checkWithinVideo(calculateSeconds(fromTime))
			toTime = ""		# take all until end
			duration = ""
		}
		else	{
			durationSeconds = checkFromTo(fromTime, toTime)	# checks both for correctness and existence
			toTime = "-to " toTime
			duration = "-t " durationSeconds
		}
		
		mpegts = toMpegTs ? " -bsf:v h264_mp4toannexb -f mpegts " : ""
		
		fileNr++
		
		# output seeking by decoding, slow, fails with MPEGTS
		# commands[fileNr] = "ffmpeg -v error -y -i " videoFile " -ss " fromTime " " toTime " -c copy -avoid_negative_ts 1 " mpegts nextClipFile()
		
		# input seeking by keyframes, fast, not precise, works with MPEGTS
		commands[fileNr] = "ffmpeg -v error -y -ss " fromTime " " duration " -i " videoFile " -c copy -avoid_negative_ts 1 " mpegts nextClipFile(fileNr)
	}
	
	function executeCommand(command)	{
		print command
		exitCode = system(command)
		if (exitCode != 0)
			executionError("Command failed with exit " exitCode ": " command, exitCode)
	}
	
	function checkFromTo(from, to)	{
		fromSeconds = calculateSeconds(from)
		toSeconds = calculateSeconds(to)
		
		if (fromSeconds < 0)
			error("Begin-time " fromSeconds " is negative: " $0, 7)
			
		if (fromSeconds >= toSeconds)
			error("Begin-time " from " is greater or equal end-time " to, 7)
		
		checkWithinVideo(toSeconds)
		return toSeconds - fromSeconds
	}
	
	function checkWithinVideo(timeInSeconds)	{
		if (timeInSeconds > 0)	{	# no need to check zero
			durationCommand = "ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 " videoFile
			durationCommand | getline videoSeconds
			close(durationCommand)
			if ( ! videoSeconds )
				error("Could not read video seconds from " videoFile)
			
			print "Checking if " videoFile " having " videoSeconds " seconds contains " timeInSeconds >"/dev/stderr"
			if (timeInSeconds >= videoSeconds)
				error("Time " timeInSeconds " is out of video bounds (" videoSeconds " seconds): " $0, 7)
		}
		return videoSeconds
	}
	
	function calculateSeconds(time)	{
		numberOfTimeParts = split(time, timeParts, ":")
		resultTime = 0
		for (i in timeParts)	{
			timePart = timeParts[i]
			if (timePart !~ /^[0-9\.]+$/)
				error("Invalid time part: " timePart, 7)
			
			resultTime += timePart
			if (i < numberOfTimeParts)
				resultTime *= 60
		}
		return resultTime
	}
	
	function error(message, exitCode)	{
		print "ERROR in '$cuttingPlan' at line " NR ": " message >"/dev/stderr"
		quit(exitCode)
	}
	
	function executionError(message, exitCode)	{
		print "EXECUTION ERROR: " message >"/dev/stderr"
		quit(exitCode)
	}
	
	function quit(exitCode)	{
		errNo = exitCode	# make END do nothing
		exit exitCode
	}
	
	function exists(filePath)	{
		return system("test -f " filePath) == 0
	}
	
	
	/^[a-zA-Z0-9_\-]+\.MP4[ \t]*$/	{	# next video file
		videoFile = $1
		if ( ! exists(videoFile) )
			error("file does not exist or is empty: " videoFile, 8)
	}
	
	/^[0-9]+:?[0-9\.]*[ \t]/	{	# next start - end times of a clip to extract
		if (videoFile)	# there was a video file name before
			addCommand($1, ($2 == "-" ? $3 : $2))
		else
			error("Found start - end time without video file: " $0, 9)
	}
	
	/^all/	{	# copy the whole video as clip
		addCommand("0", "end")
	}
	
	END	{
		if ( ! errNo )	# error() would set this
			if ( ! fileNr )
				error("No video cuts were found in '$cuttingPlan' !", 9)
			else
				for (c in commands)	# execute all collected commands
					executeCommand(commands[c])
	}
' $cuttingPlan || exit $?

echo "Generated cut videos in `pwd`/$cutsDir"
