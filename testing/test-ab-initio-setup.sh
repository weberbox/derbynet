#! /bin/sh

# Performs some basic tests on a newly-installed or partially-installed website.
#
# For a remote server, we wouldn't have access to the 'local' directory, so this
# test only runs for localhost
#
# Worse, since we want to manipulate the directory directly, without going
# through the web server, we have to know or assume what the directory structure
# is.

BASE_URL=$1
set -e -E -o pipefail
source `dirname $0`/common.sh

if [ "$BASE_URL" = "localhost/derbynet" ]; then
    if [ -d /Library/WebServer/Documents/derbynet/ ]; then
        # Mac
        BASEDIR=/Library/WebServer/Documents/derbynet
        DATADIR=~/Public/DerbyNet
    elif [ -d /var/www/html/derbynet/ ]; then
        # Debian/Linux
        BASEDIR=/var/www/html/derbynet
        DATADIR=/var/lib/derbynet
    else
        tput setaf 1  # red text
        echo Host system type not recognized
        tput setaf 0  # black text
    fi

    YEAR=`date +%Y`
    [ -d $DATADIR ] || mkdir -m 777 $DATADIR

    echo Performing ab initio set-up testing on $BASEDIR

    # Clean up results from a failed previous attempt, if any
    if [ -d $BASEDIR/xlocalx ] ; then
        tput setaf 2  # green text
        echo Recovering xlocalx directory
        tput setaf 0  # black text

        [ -d $BASEDIR/local ] && rm -rf $BASEDIR/local
        mv $BASEDIR/xlocalx $BASEDIR/local
    fi
    [ -d $DATADIR/$YEAR/this-will-succeed ] && rm -rf $DATADIR/$YEAR/this-will-succeed

    ## ----------------------------------
    echo '   ' With no local directory...
    mv $BASEDIR/local $BASEDIR/xlocalx

    # Redirects to set-up page
    curl_get index.php | expect_one 'You need to create'
    
    ## ----------------------------------
    echo '   ' With unwritable directory
    mkdir -m 0555 $BASEDIR/local
    curl_get index.php | expect_one "but isn't writable"

    ## ----------------------------------
    echo '   ' With writable empty directory but no default path
    chmod 0777 $BASEDIR/local
    curl_get index.php | expect_one 'configure the database first'

    curl_post action.php "action=setup.nodata&ez-new=this-will-fail" | check_failure

    [ -z "`ls $BASEDIR/local`" ] || test_fails Unexpected files created!

    ## ----------------------------------
    echo '   ' Successful set-up
    cp $BASEDIR/xlocalx/default-file-path.inc $BASEDIR/local

    curl_get index.php | expect_one 'configure the database first'
    curl_post action.php "action=setup.nodata&ez-new=this-will-succeed" | check_success

    # confirm config-database and config-roles
    [ -f $BASEDIR/local/config-database.inc ] || test_fails Missing database config
    [ -f $BASEDIR/local/config-roles.inc ] || test_fails Missing roles config

    # confirm sqlite database file and directories
    [ -f $DATADIR/$YEAR/this-will-succeed/derbynet.sqlite3 ] || test_fails Database not created
    [ -d $DATADIR/$YEAR/this-will-succeed/cars ] || test_fails Car photo directory not created
    [ -d $DATADIR/$YEAR/this-will-succeed/racers ] || test_fails Racer photo directory not created
    [ -d $DATADIR/$YEAR/this-will-succeed/videos ] || test_fails Video directory not created

    ## ----------------------------------
    echo '   ' Removing database file
    rm -rf $DATADIR/$YEAR/this-will-succeed
    
    curl_get index.php | expect_one 'a problem opening the database'

    ## ----------------------------------
    echo '   ' Cleaning up
    rm -rf $BASEDIR/local
    mv $BASEDIR/xlocalx $BASEDIR/local

else
    tput setaf 2  # green text
    echo Server is remote, so not testing ab initio set-up
    tput setaf 0  # black text
fi
