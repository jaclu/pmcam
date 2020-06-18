#!/usr/bin/env bash

#
# Primary variables you might want to change
#
OUTPUT_DIR=../changed_imgs
DIFF_LIMIT=19
SOURCE_WILDCARD=*.JPG


DIFF_IMG=diff.png
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

mkdir -p $OUTPUT_DIR
PREVIOUS_IMAGE=""
for NEXT_IMAGE in $SOURCE_WILDCARD ; do    
    if [[ "$PREVIOUS_IMAGE" != "" ]]; then
	# For some reason, `compare` outputs the result to stderr so
	# it's not possibly to directly get the result. It needs to be
	# redirected to a temp file first.
	compare -fuzz 20% -metric ae "$PREVIOUS_IMAGE" "$NEXT_IMAGE" $DIFF_IMG 2> $DIFF_RESULT_FILE
	DIFF="$(cat $DIFF_RESULT_FILE)"
	fn_cleanup
	if [ "$DIFF" -gt $DIFF_LIMIT ]; then
	    cp "$NEXT_IMAGE" $OUTPUT_DIR
	    echo "keep $NEXT_IMAGE (Diff = $DIFF)"
	    PREVIOUS_IMAGE="$NEXT_IMAGE"
	fi
    else
	cp "$NEXT_IMAGE" $OUTPUT_DIR
	PREVIOUS_IMAGE="$NEXT_IMAGE"
    fi
done
