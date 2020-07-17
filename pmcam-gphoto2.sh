#!/usr/bin/env bash

#
# Primary variables you might want to change
#
# Personal notes for DIFF_LIMIT
# EM-5 II
# S SF 1280x960 16:9 (720 vid format) imgsize aprox 700KB
#     15000 - slightly sensitive but wont miss anything major
#
DIFF_LIMIT=800 # depends on image quality and change level that is of interest

CAPTURE_INTERVAL="2"

OUTPUT_DIR=../filtered_$DIFF_LIMIT
SOURCE_WILDCARD=.JPG # Do not include * this will fail the file listing!

# Booleans, set to true or false
DISPLAY_SKIPPED=false


#
# For TIME_STAMP & RESIZE, set them to "" if the feature is
# not desired.
#

# you will probably need to play arround with -pointsize and offset in
# -annotate, depending on your image size...
#
# Also note that if RESIZE is used, diff is calculated on the converted images,
# including timestamp, so there will always be a baseline difference between
# two images due to the timestamp, so you might need to increase DIFF_LIMIT
# accordingly. This also means RESIZE is incompatible with REMOVE_SOURCE=true
#
TIME_STAMP="-fill white -gravity SouthWest -pointsize 20 -annotate +15+10 %[exif:DateTimeOriginal]"
#TIME_STAMP=""


#
# Settings normally not needed to be changed below
#

DIFF_IMG=$OUTPUT_DIR/diff.png
DIFF_RESULT_FILE=$OUTPUT_DIR/diff_results.txt
FILE_LIST=$OUTPUT_DIR/all_matching_files


fn_terminate_script() {
	fn_cleanup
	echo "SIGINT caught."
	exit 0
}
trap 'fn_terminate_script' SIGINT

fn_cleanup() {
	rm -f $DIFF_IMG $DIFF_RESULT_FILE $FILE_LIST
}

fn_verify_boolean_params() {
    local b=$1
    if [ $b != true ]; then
	if [ $b != false ]; then
	    echo "Invalid boolean value: $var_name = $b"
	    exit 1
	fi
    fi    
}

fn_copy_image() {
    if [ "$TIME_STAMP $RESIZE" != " " ] ; then
	convert $1 $TIME_STAMP $RESIZE $2/$1
    else
	cp $1 $2
    fi
}

fn_get_image() {
    # use $NEXT_IMAGE over $CURENT_IMAGE in echo to skip path
    echo "keep $LATEST_THUMB - $DIFF"
    gphoto2 --capture-image-and-download --filename="$OUTPUT_DIR/$(date +"%Y%m%dT%H%M%S%N")_%03n.jpg"
    PREVIOUS_THUMB="$LATEST_THUMB"
}

#
# Prepare environ
#
fn_verify_boolean_params $DISPLAY_SKIPPED

mkdir -p $OUTPUT_DIR/thumb
PREVIOUS_THUMB=""

#
# Main loop
#
while true ; do
    TIMESTAMP="$(date +"%Y%m%dT%H%M%S%N")"
    LATEST_THUMB="$OUTPUT_DIR/thumb/$TIMESTAMP.jpg"
    echo "Capturing $FILENAME"
    gphoto2 --capture-preview --filename="$LATEST_THUMB"

    if [ "$PREVIOUS_THUMB" != "" ]; then
	# For some reason, `compare` outputs the result to stderr so
	# it's not possibly to directly get the result. It needs to be
	# redirected to a temp file first.
	compare -fuzz 20% -metric ae "$PREVIOUS_THUMB" "$LATEST_THUMB" $DIFF_IMG 2> $DIFF_RESULT_FILE
	DIFF="$(cat $DIFF_RESULT_FILE)"
	
	if [ "$DIFF" -lt $DIFF_LIMIT ]; then
	    #
	    # Not enough diff, skip this image
	    #
	    if [ $DISPLAY_SKIPPED == true ]; then
		# use $NEXT_IMAGE over $CURENT_IMAGE in echo to skip path
		echo "    skipped $NEXT_IMAGE (Diff: $DIFF)"
	    fi
	else
	    #
	    # Enough diff, keep this image!
	    #
	    fn_use_image
	fi
    else
	# Always keep first image processed
	fn_get_image
	PREVIOUS_THUMB="$LATEST_THUMB"
    fi
    echo -n "sleeping... "
    sleep $CAPTURE_INTERVAL
    echo "Done!"
done
