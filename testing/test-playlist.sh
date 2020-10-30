#! /bin/bash

BASE_URL=$1
set -e -E -o pipefail
source `dirname $0`/common.sh

user_login_coordinator

`dirname $0`/reset-database.sh $BASE_URL

# $1 = car number
# $2 = classname
function make_racer() {
    curl_post action.php \
              "action=racer.import&firstname=First$1&lastname=Last$1&classname=$2&carnumber=$1" \
        | check_success
}

make_racer 101 Den1
make_racer 102 Den1
make_racer 201 Den2
make_racer 202 Den2
make_racer 203 Den2
make_racer 301 Den3
make_racer 302 Den3

curl_post action.php "action=class.add&name=TwoThree&constituent_2&constituent_3" | check_success

curl_post action.php "action=racer.bulk&who=all&what=checkin" | check_success

KIOSK1=FAKE-KIOSK1

curl_get "action.php?query=poll.kiosk&address=$KIOSK1" | expect_one kiosks/identify.kiosk
curl_post action.php "action=kiosk.assign&address=$KIOSK1&name=Main" | check_success
curl_post action.php "action=kiosk.assign&address=$KIOSK1&page=kiosks/welcome.kiosk" | check_success
curl_get "action.php?query=poll.kiosk&address=$KIOSK1" | expect_one kiosks/welcome.kiosk

# Assuming Den1's first round is roundid = 1, etc.
#
# Assuming sceneid 4 is "Racing"  with now-racing page on Main,
# and sceneid 5 is "Awards", with awards-presentation page on Main

curl_post action.php "action=settings.write&unused-lane-mask=0&n-lanes=2" | check_success
curl_post action.php "action=settings.write&racing_scene=4" | check_success

curl_post action.php "action=schedule.generate&roundid=1" | check_success

curl_post action.php "action=playlist.new&classid=1&round=1&sceneid_at_finish=5" | check_success
curl_post action.php "action=playlist.new&classid=2&round=1&n_times_per_lane=1&continue_racing=1" | check_success
curl_post action.php "action=playlist.new&classid=3&round=1&n_times_per_lane=1&continue_racing=1" | check_success
curl_post action.php "action=playlist.new&classid=4&round=1&top=3&bucketed=0&n_times_per_lane=2" | check_success

# Race roundid=1:
curl_post action.php "action=heat.select&roundid=1&now_racing=1" | check_success
curl_get "action.php?query=poll.kiosk&address=$KIOSK1" | expect_one kiosks/now-racing.kiosk

curl_post action.php "action=timer-message&message=STARTED" | check_success
curl_post action.php "action=timer-message&message=FINISHED&lane1=1.00&lane2=2.00" | check_success
curl_post action.php "action=timer-message&message=STARTED" | check_success
curl_post action.php "action=timer-message&message=FINISHED&lane1=1.00&lane2=2.00" | check_success
# After the first round, we should have Den2 scheduled and teed up, but not
# racing.  After a brief pause, we should see the scene switched to Awards
echo "Waiting for scene change to take effect..."
sleep 11s
curl_get "action.php?query=poll.kiosk&address=$KIOSK1" | expect_one kiosks/award-presentations.kiosk
curl_get "action.php?query=poll.coordinator" | grep current-heat | expect_one roundid=.2.
curl_get "action.php?query=poll.coordinator" | grep current-heat | expect_one now-racing=.0.

curl_post action.php "action=kiosk.assign&address=$KIOSK1&page=kiosks/flag.kiosk" | check_success

# Race roundid=2:
curl_post action.php "action=heat.select&now_racing=1" | check_success
curl_get "action.php?query=poll.kiosk&address=$KIOSK1" | expect_one kiosks/now-racing.kiosk

curl_post action.php "action=timer-message&message=STARTED" | check_success
curl_post action.php "action=timer-message&message=FINISHED&lane1=1.00&lane2=1.20" | check_success
curl_post action.php "action=timer-message&message=STARTED" | check_success
curl_post action.php "action=timer-message&message=FINISHED&lane1=1.00&lane2=1.30" | check_success
curl_post action.php "action=timer-message&message=STARTED" | check_success
curl_post action.php "action=timer-message&message=FINISHED&lane1=1.00&lane2=1.40" | check_success
# No scene change, move right into round 3
curl_get "action.php?query=poll.kiosk&address=$KIOSK1" | expect_one "kiosks/now-racing.kiosk"
curl_get "action.php?query=poll.coordinator" | grep current-heat | expect_one roundid=.3.
curl_get "action.php?query=poll.coordinator" | grep current-heat | expect_one now-racing=.1.

curl_post action.php "action=timer-message&message=STARTED" | check_success
curl_post action.php "action=timer-message&message=FINISHED&lane1=1.00&lane2=1.20" | check_success
curl_post action.php "action=timer-message&message=STARTED" | check_success
curl_post action.php "action=timer-message&message=FINISHED&lane1=1.00&lane2=1.40" | check_success

# No scene change, move right into round 4, which picks a roster
curl_get "action.php?query=poll.kiosk&address=$KIOSK1" | expect_one "kiosks/now-racing.kiosk"
curl_get "action.php?query=poll.coordinator" | grep current-heat | expect_one roundid=.4.
curl_get "action.php?query=poll.coordinator" | grep current-heat | expect_one now-racing=.1.

# First heat: 203 v. 201
curl_get "action.php?query=poll.coordinator" | grep 'racer lane=.1.' | expect_one carnumber=.203.
curl_get "action.php?query=poll.coordinator" | grep 'racer lane=.2.' | expect_one carnumber=.201.
curl_post action.php "action=timer-message&message=STARTED" | check_success
curl_post action.php "action=timer-message&message=FINISHED&lane1=1.00&lane2=1.20" | check_success
# Second heat: 302 v. 203
curl_get "action.php?query=poll.coordinator" | grep 'racer lane=.1.' | expect_one carnumber=.302.
curl_get "action.php?query=poll.coordinator" | grep 'racer lane=.2.' | expect_one carnumber=.203.
curl_post action.php "action=timer-message&message=STARTED" | check_success
curl_post action.php "action=timer-message&message=FINISHED&lane1=1.00&lane2=1.20" | check_success
# Third heat: 201 v. 302
curl_get "action.php?query=poll.coordinator" | grep 'racer lane=.1.' | expect_one carnumber=.201.
curl_get "action.php?query=poll.coordinator" | grep 'racer lane=.2.' | expect_one carnumber=.302.
