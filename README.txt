How to Contribute
============

First enable devloper mode on your Roku device:

http://sdkdocs.roku.com/display/sdkdoc/Developer+Guide

Then, zip up the source code directory. Visit 192.168.1.100 in your browser, updating the IP address with the IP of the Roku device. From here you can upload the zip to the device.

To debug, use any telnet client on port 8085 of the Roku. In windows, open a command promt:

telnet
o 192.168.1.100 8085


Guidelines for Pull Requests
============

* One change per pull request. Please make sure the pull request does not contain more than one change, or changes that are unrelated to the issue being addressed.
* Make sure to preserve file formatting. Do not make significant changes to whitespace, tabs, etc because this will make it more difficult to review the changes.
* Comment your code. Do not recite the code in comment form, but do comment on why you're doing things one way or another.


Changelog
============

1.2:

* Added global event loop. All screens have been refactored to use it.
* Added remote control support
* Unified all duplicate metadata parsing. Features are now consistent regardless of item types.
* Most data is now background loaded for a more responsive presentation
* Image indicators are now available on all screens
* Display clock in top right of home page
* Support WakeOnLan
* Added logo screen saver
* Added new splash screen
* Updated theme to a darker, flatter style
* Added placeholder for custom themes, to be implemented later
* Added support for latest api features. New progress api's are used to report additional information to the server.
* Added user configurable device display name (for reporting activity to the server)
* Server now detects when the client goes offline (within 1 minute), rather than waiting for an idle timer
* Detail page image shape is chosen automatically based on image aspect ratio, rather than item type
* All folder types can now be browsed, including games. Some will use the video detail screen when selected.
* Cast & Crew added to video page
* Added now playing context menu to song list page, with next, previous, shuffle, and loop functions
* Stopping an intro is now able to prevent playback of the main feature
* Support automatic selection of optimal media source
* Increased possibilities of direct play video
* Add additional checks against direct play to avoid it based on new criteria
* Support user's configured audio and subtitle language preferences
* Display transcoding info in video screen OSD
* Servers are saved using friendly name reported by the server
* Support channels
* Support video playlists


1.17 - Added support for photos; Redesigned home screen toggles; Bug fixes; More bug fixes; Other minor features;

1.16.7 - Fixed login problem introduced by latest server release;

1.16.6 - Minor bug fixes for legacy devices;

1.16.5 - More bug fixes for legacy devices; Added server successfully found page;

1.16.4 - Minor bug fixes for legacy devices;

1.16.3 - Redesigned server configuration; Now allows multiple servers; Bug fixes;

1.16.2 - Add mark/unmark played/favorite; Added favorite movies to home screen; Add music video support; Allow enhanced images on collections;

1.16.1 - Bug fixes; Server restart check; Warning for ISO/Folder rips playback; Improved trailer playback;

1.16 - Added collections; Improve audio/video direct play settings; Added support for other audio and subtitles; Added played/progress indicators; Added enhanced image support; Added auto-select next tv episode; Bug fixes;

1.15 - New Theme; Added popup bubble; Added dynamic loading for speed improvment; Bug fixes;

1.14 - Bug fixes; Speed improvements;

1.13 - Added music genres; Bug fixes; Added theme music preferences;

1.12 - Added theme music to TV browsing; Fixed bug with video playback on latest server;

1.11 - Added music; Bug fixes; Added Next Episodes to watch for TV; Added display toggle on home screen to toggle between resume, latest and favorite items;

1.10 - Fixed problem with server requesting multiple streams; Added new video quality preference; Added new jump to letter feature for movies and tv;

1.9 - Added additional button commands; Fixed problem with chapter selection in movies; Added more info screen while video is playing;

1.8 - Switched to HLS; Fixed problem with direct play offset; Added FF/RW for direct play; Added display preferences

1.7 - Added custom video player; Added support for TV chapters

1.6 - Added support for Movie Box Sets; Added support for Movie chapters

1.5 - Added Genres support for TV/Movies

1.4 - Added prev/next navigation to episode level; Added password checks for profiles; Hide sections that have no items

1.3 - Saves playstate to server; Added support for DVD/Bluray folder rips, ISO playback; Added prev/next navigation from detail screen on movies; Checks in activity with server

1.2 - Added Save User / Switch User Ability; Added Play/Resume from server

1.1 - Added Video Playback for mkv, mp4, avi

1.0 - Initial Browsing
