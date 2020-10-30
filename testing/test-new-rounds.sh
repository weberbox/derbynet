#! /bin/bash

BASE_URL=$1
set -e -E -o pipefail
source `dirname $0`/common.sh

user_login_coordinator

## Testing the "add new round" functionality.  We're just generating the
## rosters, not making schedules or doing any racing.

# We expect there are no rounds beyond a first round for each of the classes
# Note that test-den-changes.sh created and then deleted TheNotLastClass, which
# results in one extra initial round, now deleted
curl_post action.php "action=roster.delete&roundid=8" | check_failure

# Top 3 from roundid=1
curl_post action.php "action=roster.new&roundid=1&top=3" | check_success
if [ "`grep -c '<finalist' $DEBUG_CURL`" -ne 3 ]; then
    test_fails Expecting 3 finalists
fi

# The new round should be roundid=7, which is now deletable
curl_post action.php "action=roster.delete&roundid=7" | check_success
# roundid=7 is now gone, so second deletion fails
curl_post action.php "action=roster.delete&roundid=7" | check_failure

# Top 3 from each rank in roundid=2
curl_post action.php "action=roster.new&roundid=2&top=3&bucketed=1" | check_success
# TODO: The test data doesn't track subgroups, so there's effectively no
# difference between the bucketed and non-bucketed version.
if [ "`grep -c '<finalist' $DEBUG_CURL`" -ne 3 ]; then
    test_fails Expecting 3 finalists
fi

# Grand Finals round, 4 from each den
# In test-basic-checkins, Bears & Freres only have 2 racers, so it's a total of 14 racers
# In test-master-schedule, Bears & Freres have 2 racers, and Webelos only 3, so it's a total of 13 finalists
curl_post action.php "action=roster.new&roundid=&top=4&bucketed=1&roundid_1=1&roundid_2=1&roundid_3=1&roundid_4=1&classname=Grand%20Finals" \
 | check_success
if [ "`grep -c '<finalist' $DEBUG_CURL`" -lt 13 -o \
     "`grep -c '<finalist' $DEBUG_CURL`" -gt 14 ]; then
    test_fails Expecting 13 or 14 finalists, not `grep -c '<finalist' $DEBUG_CURL`
fi

# <new-round roundid="xxx"/>
ROUNDID=`grep '<new-round' $DEBUG_CURL | sed -e 's/.* roundid=.\([0-9][0-9]*\).*/\1/'`

curl_post action.php "action=roster.delete&roundid=$ROUNDID" | check_success

# Grand Finals round, top 5 overall
curl_post action.php "action=roster.new&roundid=&top=5&roundid_1=1&roundid_2=1&roundid_3=1&roundid_4=1&classname=Grand%20Finals-2" | check_success
if [ "`grep -c '<finalist' $DEBUG_CURL`" -ne 5 ]; then
    test_fails Expecting 5 finalists
fi

ROUNDID=`grep '<new-round' $DEBUG_CURL | sed -e 's/.* roundid=.\([0-9][0-9]*\).*/\1/'`
curl_post action.php "action=roster.delete&roundid=$ROUNDID" | check_success
