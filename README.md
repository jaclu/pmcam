# pmcam - poor man's video capture with motion detection in Bash

This simple Bash script inspects all images in current dir, and copies those with enough change to a separate dir.
The original from laurent22/pmcam grabed images from a webcam. In my case I use a tethered camera that takes images at regular intervals to a date named directory, and then use this script to copy images with enough change to a output directory. Then every now and then I clear the source dir from old pictures.


## Installation

### OS X

	brew install imagemagick

### Linux (Debian)

	sudo apt-get install imagemagick

### Windows

(Not tested)

* Install [ImageMagick](http://www.imagemagick.org/script/binary-releases.php)

## Configuration

The primary config lines are:

OUTPUT_DIR=../changed_imgs
DIFF_LIMIT=19
SOURCE_WILDCARD=*.JPG

Set them as you see fit.


## Usage

cd to dir where images to be processed are located, then run it as:

	./pmcam.sh

To stop the script, press Ctrl + C.


## License

MIT
