#!/usr/bin/env bash

#
# Primary variables you might want to change
#
# Personal notes for DIFF_LIMIT
# using an Olympus EM-5 II
# S SF 1280x960 16:9 (720 vid format) imgsize aprox 700KB
#     15000 - slightly sensitive but wont miss anything major
#
DIFF_LIMIT=15000 # depends on image quality and change level that is of interest
OUTPUT_DIR=filtered_$DIFF_LIMIT
SOURCE_WILDCARD=.JPG # Do not include * this will fail the file listing!

# Booleans, set to true or false
REMOVE_SOURCE=true  # remoces processed source images
DISPLAY_SKIPPED=true
# if true terminates once all images are processed, otherwise sleeps and
# then rescans the directory. Usefull for monitoring when the camera is
# running, and adding images in an ongoing fashion.
SINGLE_PASS=false


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

RESIZE=""
#RESIZE="-resize 1280x720"


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

fn_use_image() {
    # use $NEXT_IMAGE over $CURENT_IMAGE in echo to skip path
    echo "keep $NEXT_IMAGE - $DIFF"
    if [ $REMOVE_SOURCE == true ] ; then
	if [ "$PREVIOUS_IMAGE" != "" ] ; then
	    rm $PREVIOUS_IMAGE
	fi
    fi
    if [ "$RESIZE" != "" ]; then
	PREVIOUS_IMAGE="$CURENT_IMAGE"
    else
	# late copy, compare done on original
	fn_copy_image "$NEXT_IMAGE" $OUTPUT_DIR
	PREVIOUS_IMAGE="$NEXT_IMAGE"
    fi
}

#
# Prepare environ
#
fn_verify_boolean_params $REMOVE_SOURCE
fn_verify_boolean_params $DISPLAY_SKIPPED
fn_verify_boolean_params $SINGLE_PASS

if [ "$RESIZE" != "" ]; then
    if [ $REMOVE_SOURCE == true ]; then
	echo "*** Configuration Error: RESIZE and REMOVE_SOURCE"
	echo "    can not both be set at the same time !!"
	exit 1
    fi
fi

mkdir -p $OUTPUT_DIR
PREVIOUS_IMAGE=""

#
# Main loop
#
while :; do

    #
    # for NEXT_IMAGE in $SOURCE_WILDCARD ; do
    # gave me problems in the sense that images where not always handled in
    # correct oreder, my workaround was to use ls | sort -V and store it in
    # a file.
    #
    ls | sort -V | grep $SOURCE_WILDCARD > $FILE_LIST
    
    while IFS="" read -r NEXT_IMAGE || [ -n "$NEXT_IMAGE" ] ; do
	if [ "$NEXT_IMAGE" == "$PREVIOUS_IMAGE" ]; then
	    # most likely we ran out of imgs, and started another loop
	    continue 
	fi	
	if [ "$RESIZE" != "" ]; then
	    # in this case we do early copy, in order to make the compare
	    # less demanding
	    fn_copy_image "$NEXT_IMAGE" $OUTPUT_DIR
	    CURENT_IMAGE="$OUTPUT_DIR/$NEXT_IMAGE"
	else
	    CURENT_IMAGE="$NEXT_IMAGE"	
	fi
	
	if [ "$PREVIOUS_IMAGE" != "" ]; then
	    # For some reason, `compare` outputs the result to stderr so
	    # it's not possibly to directly get the result. It needs to be
	    # redirected to a temp file first.
	    compare -fuzz 20% -metric ae "$PREVIOUS_IMAGE" "$CURENT_IMAGE" $DIFF_IMG 2> $DIFF_RESULT_FILE
	    DIFF="$(cat $DIFF_RESULT_FILE)"
	    
	    if [ "$DIFF" -lt "$DIFF_LIMIT" ]; then
		#
		# Not enough diff, skip this image
		#
		if [ $DISPLAY_SKIPPED == true ]; then
		    # use $NEXT_IMAGE over $CURENT_IMAGE in echo to skip path
		    echo "    skipped $NEXT_IMAGE (Diff: $DIFF)"
		fi
		if [ $REMOVE_SOURCE == true ]; then
		    if [ "$NEXT_IMAGE" != "$SOURCE_WILDCARD" ] ; then
			if [ "$NEXT_IMAGE" != "$PREVIOUS_IMAGE" ] ; then
			    rm "$NEXT_IMAGE"
			fi
		    fi
		fi
		if [ "$RESIZE" != "" ]; then
		    # Since we did early copy, now we have to delete the copied file
		    rm "$CURENT_IMAGE"
		fi
	    else
		#
		# Enough diff, keep this image!
		#
		fn_use_image
	    fi
	else
	    # Always keep first image processed
	    fn_use_image
	    PREVIOUS_IMAGE="$CURENT_IMAGE"
	fi
    done < $FILE_LIST

    if [ $SINGLE_PASS == true ]; then
	fn_cleanup
	exit 0
    fi
    echo -n "===============   No files sleeping a while... "
    sleep 2
    echo "Lets continue!   ==============="
done
