#! /bin/sh
#
# This script uses uses a bar code scanner and a tethered camera to automate
# photo capture for your pinewood derby event.  See
# http://www.derbytalk.com/viewtopic.php?f=25&t=8253&p=79318 for more
# disccussion.
#
# Usage: photostand.sh <web server base URL>
# E.g.,  photostand.sh http://192.168.1.37/derbynet
#
# If the base URL is not given on the command line, and it's available from
# either /boot/derbynet.conf or /etc/derbynet.conf, that value will be used.
#
# The script logs in to the server when started, then loops waiting for barcodes
# to be scanned.  Check the server's php.ini, particularly
# session.gc_maxlifetime, to be sure that session cookies won't get reclaimed
# before we're done.
#

# Establish default values; photo-preamble will override from user config files.
#  Looks in /dev/input/by-id for any of the scanner devs, or just any device at all.
BARCODE_SCANNER_DEVS=""

# One of: "chdkptp", "fswebcam", or "gphoto2"; an empty string is interpreted as gphoto2.
PHOTO_CAPTURE=

FSWEBCAM_ARGS="--config /usr/share/derbynet/conf/fswebcam.conf"

SELF="$0"
# readlink -f exists in linux (particularly RPi), but not e.g. Mac
[ -L "$SELF" ] && SELF=`readlink -f "$SELF"`
SELF_DIR=`dirname "$SELF"`
LIB_DIR="$SELF_DIR/lib"

. "$LIB_DIR"/photo-preamble.sh
. "$LIB_DIR"/photo-functions.sh
READ_BARCODE="$LIB_DIR"/read_barcode.py

rm uploads.log > /dev/null
rm checkins.log > /dev/null

killall_gvfs_volume_monitor

do_login

define_photo_directory

check_scanner

# Even if camera is missing, allow barcode loop to proceed, so at least QUIT
# command can be recognized.
check_camera &

while true ; do
    DEV="`find_barcode_scanner`"
    if [ -z "$DEV" ] ; then
        announce no-scanner
        sleep 5s
        continue
    fi
    BARCODE=`$READ_BARCODE "$DEV"`
    echo Scanned $BARCODE
    CAR_NO=`echo $BARCODE | grep -e "^PWD" | sed -e "s/^PWD//"`
    if [ "$BARCODE" = "QUITQUITQUIT" ] ; then
        announce terminating
        sudo shutdown -h now
    elif [ "$BARCODE" = "PWDspeedtest" ] ; then
        upload_speed_test
    elif [ "$CAR_NO" ] ; then

        maybe_check_in_racer

        echo Capturing photo Car$CAR_NO.jpg
        CAPTURE_OK=0
        if [ "$PHOTO_CAPTURE" = "chdkptp" ] ; then
            prepare_camera_before_shot
            # remoteshoot takes a file name without extension
            chdkptp -c -e"rec" -e"remoteshoot $PHOTO_DIR/Car$CAR_NO" \
                    && CAPTURE_OK=1
        elif [ "$PHOTO_CAPTURE" = "fswebcam" ] ; then
            fswebcam $FSWEBCAM_ARGS "$PHOTO_DIR/Car$CAR_NO.jpg"
            # fswebcam always returns 0, whether successful or not
            CAPTURE_OK=1
        else
            gphoto2 --filename "$PHOTO_DIR/Car$CAR_NO.jpg"  --force-overwrite \
                    --capture-image-and-download \
                && CAPTURE_OK=1
        fi

        if [ $CAPTURE_OK -eq 1 ] ; then
            announce capture-ok
            upload_photo "$PHOTO_DIR/Car$CAR_NO.jpg"
        else
            announce capture-failed
        fi
    else
        echo Rejecting scanned barcode $BARCODE
        announce unrecognized-barcode
    fi
done
