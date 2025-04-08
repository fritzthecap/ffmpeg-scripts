# ffmpeg-scripts
UNIX shell scripts for video-cutting with **ffmpeg** (which must be pre-installed).

Every script displays its purpose and commandine-syntax when called without arguments.
The scripts were written for the MP4 video format.

Some of the scripts call other scripts. 
Most of them expect a video-directory where .MP4 (or .mp4) files are to be processed.

----

Typically I use following workflow to cut my videos:

- listVideos.sh myVideoDirectory

This creates a _cuts.txt_ file (cutting plan) in _myVideoDirectory_, which I use to define 1-n cuts for any video in that directory.  
Additionally I mostly create a file _title.txt_ in _myVideoDirectory_ where I write the video title into.

Then I edit _cuts.txt_ and write 1-n intervals below every listed video, each interval in a separate line.  
Indenting a line with 1-n spaces is like a comment, every indented line would be ignored.

----

Here is an example cutting plan (_myVideoDirectory/cuts.txt_), already edited, containing cut-intervals:

```
hikemountain-map.MP4
all

  parking lot
20250328_092003.mp4
7 25.6
1:32 end

  20250328_092136.mp4

  summit view
20250328_092806.mp4
4 16
```
Explanations:

The first cut will be _hikemountain-map.MP4_, such a video can be created by _imageToVideo.sh_.  
The keyword 'all' is for taking the entire video. Videos without any interval definition would be ignored.

" parking lot" is indented, thus it will be ignored. It is a comment for me to know what the cut will contain.  
From video _20250328_092003.mp4_ the intervals from second 7 to 25.6 and 1:32 to the video's end (keyword 'end') will be taken.  
For videos that are longer than a minute I use the format _minute:second_, as can be seen on 1:32.  
If an interval definition is out of range, the script would stop with an error message with the according line number in _cuts.txt_.

The video _20250328_092136.mp4_ will be ignored, because it has been indented.

From video _20250328_092806.mp4_ the intervals from second 4 to 16 will be taken.

----

If I want a title for my video, I process the _title.txt_ file via

- titleForVideos.sh myVideoDirectory/videoToTakeTitleImageFrom.MP4 32.4

This would extract the image at second 32.4 from _videoToTakeTitleImageFrom.MP4_, put the text in _title.txt_ over it, and store that as _TITLE.MP4_ in same directory.
The file _TITLE.MP4_ must not be in _cuts.txt_, it would be found atomatically by the now following _cutJoinVideos.sh_.

- cutJoinVideos.sh myVideoDirectory

This will create a sub-directory named _cuts_ where all cuts defined in _cuts.txt_ will be stored as file, sorted like they were ordered in _cuts.txt_.
After that, the script will join all cuts to a video _myVideoDirectory.MP4_ (named like the directory), which is the final result, containing also the optional _TITLE.MP4_.

