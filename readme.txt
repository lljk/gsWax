
gsWax 0.12.01 wicked-icked alpha

  This thing's not done, but it basically runs at this point, so I thought I'd put it out there.

  You'll need green_shoes (https://github.com/ashbb/green_shoes), and gstreamer (http://rubygems.org/gems/gstreamer) for this business to work.  If you're running Windows, just do the following two steps:

  - gem install green_shoes
  - gem install gstreamer

  If you run Linux, you've probably already got the gstreamer library, and you just need the gem - if the library is not installed, you should be able to install it easily through your package manager.

  So, fire up `gsWax.rb` and load up your favorite tracks...

  LOADING TRACKS:
  There are a few ways to add tracks - you can drag and drop files or directories onto the main window, open up the directory browser and navigate to files or directories you want to play, or open the playlist and click "add tracks."

  THE DIRECTORY BROWSER:
  On the left you'll see an image of the directory you are currently in (the first image found or default.)  Below that is a box with the path to the current directory.  Clicking in this box will move you up one directory.  On the bottom left are two buttons for adding whatever is selected on the right to the playlist.

  On the right all subdirectories and music files (.flac, .ogg, .mp3, .wav) are shown.  Double clicking on a subdirectory enters that directory, and on a file plays it immediately.

  THE PLAYLIST:
  Should be pretty self-explanatory.  Double clicking on a track in the playlist will also play it immediately.

  THE SETTINGS:
  Here you can set the default directory for the browser, the scale of the player, the background and text colors, the text font, and the title format to be displayed.  Fields in the title format are separated by pound signs (#) - everything else is displayed as is.

  Check out the screenshot for basic playback, shuffle, seeking, volume, etc...

  Please get back to me with any problems/questions/comments.

  Rock on...

  - j
