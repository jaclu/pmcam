#!/usr/bin/env bash

#
# Primary variables you might want to change
#
DIFF_LIMIT=1400
OUTPUT_DIR=../changed_$DIFF_LIMIT
SOURCE_WILDCARD=*.JPG

#
# For TIME_STAMP & RESIZE, set them to "" if the feature is
# not desired.
#

# you will probably need to play arround with -pointsize and offset in
# -annotate, depending on your image size...
TIME_STAMP="-fill white -gravity SouthWest -pointsize 100 -annotate +40+25 %[exif:DateTimeOriginal]"
#TIME_STAMP=""

#RESIZE=""
RESIZE="-resize 1280x720"


#
# Settings normally not needed to be changed below
#

DIFF_IMG=$OUTPUT_DIR/diff.png
DIFF_RESULT_FILE=$OUTPUT_DIR/diff_results.txt

fn_cleanup() {
	rm -f $DIFF_IMG $DIFF_RESULT_FILE
}

fn_terminate_script() {
	fn_cleanup
	echo "SIGINT caught."
	exit 0
}
trap 'fn_terminate_script' SIGINT

fn_copy_image() {
    if [ "$TIME_STAMP $RESIZE" != " " ] ; then
	convert $1 $TIME_STAMP $RESIZE $2/$1
    else
	cp $1 $2
    fi
}


mkdir -p $OUTPUT_DIR
PREVIOUS_IMAGE=""
for NEXT_IMAGE in $SOURCE_WILDCARD ; do    
    if [[ "$PREVIOUS_IMAGE" != "" ]]; then
	fn_copy_image "$NEXT_IMAGE" $OUTPUT_DIR
	CURENT_IMAGE="$OUTPUT_DIR/$NEXT_IMAGE"
	# For some reason, `compare` outputs the result to stderr so
	# it's not possibly to directly get the result. It needs to be
	# redirected to a temp file first.
	compare -fuzz 20% -metric ae "$PREVIOUS_IMAGE" "$CURENT_IMAGE" $DIFF_IMG 2> $DIFF_RESULT_FILE
	DIFF="$(cat $DIFF_RESULT_FILE)"

	if [ "$DIFF" -lt $DIFF_LIMIT ]; then
	    # use $MEXT_IMAGE over $CURENT_IMAGE in echo to skip path
	    echo "   skipped $NEXT_IMAGE - $DIFF"
	    rm "$CURENT_IMAGE"
	else
	    # use $MEXT_IMAGE over $CURENT_IMAGE in echo to skip path
	    echo "keep $NEXT_IMAGE - $DIFF"
	    PREVIOUS_IMAGE="$CURENT_IMAGE"
	fi
    else
	fn_copy_image "$NEXT_IMAGE" $OUTPUT_DIR
	PREVIOUS_IMAGE="$OUTPUT_DIR/$NEXT_IMAGE"
    fi
done
