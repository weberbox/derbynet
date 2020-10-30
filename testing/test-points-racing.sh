#! /bin/bash


BASE_URL=$1
set -e -E -o pipefail
source `dirname $0`/common.sh

user_login_coordinator

`dirname $0`/reset-database.sh "$BASE_URL"
`dirname $0`/import-roster.sh "$BASE_URL"
### Check in every other racer...
`dirname $0`/test-basic-checkins.sh "$BASE_URL"

# Reinstate car 111
curl_post action.php "action=racer.edit&racer=11&firstname=Carroll&lastname=Cybulski&carno=111&carname=Vroom&rankid=1&exclude=0" | check_success

curl_post action.php "action=settings.write&use-points=1&use-points-checkbox" | check_success
curl_post action.php "action=settings.write&n-lanes=4" | check_success


### Schedule roundid 1
curl_post action.php "action=schedule.generate&roundid=1" | check_success
# Racing for roundid=1: 5 heats
curl_post action.php "action=heat.select&roundid=1&now_racing=1" | check_success

user_login_timer
curl_post action.php "action=timer-message&message=HELLO" | check_success
curl_post action.php "action=timer-message&message=IDENTIFIED&nlanes=4" | check_success

staged_heat4 101 121 141 111
run_heat_place 1 1   2 3 4 1
staged_heat4 111 131 101 121
run_heat_place 1 2   1 4 2 3
# Report times for this heat, let timer-message compute places
staged_heat4 121 141 111 131
run_heat 1 3   3.3 3.2 3.1 3.4
staged_heat4 131 101 121 141
run_heat_place 1 4   4 1 2 3

user_login_coordinator
curl_get "action.php?query=poll.coordinator" | grep last_heat | expect_one available
curl_post action.php "action=heat.rerun&heat=last" | check_success
curl_get "action.php?query=poll.coordinator" | grep last_heat | expect_one recoverable
curl_get "action.php?query=poll.coordinator" | expect_count 'finishtime=.. ' 4
curl_get "action.php?query=poll.coordinator" | expect_count 'finishplace=../' 4

curl_post action.php "action=heat.reinstate" | grep last_heat | expect_one none
curl_get "action.php?query=poll.coordinator" | grep "Felton Fouche" | expect_one 'finishplace=.4.'
curl_get "action.php?query=poll.coordinator" | grep "Adolfo" | expect_one 'finishplace=.1.'
curl_get "action.php?query=poll.coordinator" | grep "Derick Dreier" | expect_one 'finishplace=.2.'
curl_get "action.php?query=poll.coordinator" | grep "Jesse Jara" | expect_one 'finishplace=.3.'

curl_post action.php "action=heat.select&heat=next&now_racing=1" | check_success
user_login_timer


staged_heat4 141 111 131 101
run_heat_place 1 5   2 1 4 3  x

# Results (place):
# 111 101 121 141
# 111 101 121 131
# 111 141 121 131
# 101 121 141 131
# 111 141 101 131
#
#  car           first         last      sum(finishplace)  points
# 111         Carroll        Cybulski     4                16
# 101         Adolfo "Dolf"  Asher        8                12
# 121         Derick         Dreier      11                 9
# 141         Jesse          Jara        11                 9
# 131         Felton         Fouche      16                 4

user_login_coordinator
curl_post action.php "action=award.present&key=speed-2-1" | check_success
curl_get "action.php?query=award.current" | expect_one Asher

curl_get "action.php?query=poll.ondeck" | grep 'resultid="1"' | expect_one 'result="2nd"'
curl_get "action.php?query=poll.ondeck" | grep 'resultid="4"' | expect_one 'result="1st"'

# Test the tie in the standings:
#
# These are a little fragile in that they depend on each table row comprising
# exactly one line of text
curl_text "standings.php" | grep Carroll | expect_one "<td class=.col-insuper.>1</td>"
curl_text "standings.php" | grep Asher   | expect_one "<td class=.col-insuper.>2</td>"
curl_text "standings.php" | grep Derick  | expect_one "<td class=.col-insuper.>T3</td>"
curl_text "standings.php" | grep Jesse   | expect_one "<td class=.col-insuper.>T3</td>"
curl_text "standings.php" | grep Felton  | expect_one "<td class=.col-insuper.>5</td>"


curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '[1,"111","Carroll Cybulski","Vroom","Lions \u0026 Tigers",1,"4","16","1st","1st"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '[2,"101","Adolfo \"Dolf\" Asher","","Lions \u0026 Tigers",2,"4","12","1st","3rd"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '["T3","121","Derick Dreier","","Lions \u0026 Tigers","T3","4","9","2nd","3rd"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '["T3","141","Jesse Jara","","Lions \u0026 Tigers","T3","4","9","2nd","4th"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '[5,"131","Felton Fouche","","Lions \u0026 Tigers",5,"4","4","4th","4th"]'

# award presentation when there's a tie for 3rd
curl_post action.php "action=award.present&key=speed-3a-1" | check_success
curl_get "action.php?query=award.current" | expect_one Derick
curl_post action.php "action=award.present&key=speed-3b-1" | check_success
curl_get "action.php?query=award.current" | expect_one Jesse

# There are only two tied for 3rd place, not a third
curl_post action.php "action=award.present&key=speed-3c-1" | check_success
curl_get "action.php?query=award.current" | expect_count '<award ' 0

# There's no fourth place when there's a tie for 3rd
curl_post action.php "action=award.present&key=speed-4-1" | check_success
curl_get "action.php?query=award.current" | expect_count '<award ' 0

# One-trophy-per-racer means Felton takes 1st place in Lions
curl_post action.php "action=settings.write&one-trophy-per=1&one-trophy-per-checkbox" | check_success
curl_post action.php "action=award.present&key=speed-3a" | check_success
curl_get "action.php?query=award.current" | expect_one Derick
curl_post action.php "action=award.present&key=speed-3b" | check_success
curl_get "action.php?query=award.current" | expect_one Jesse
curl_post action.php "action=award.present&key=speed-3c" | check_success
curl_get "action.php?query=award.current" | expect_count '<award ' 0
curl_post action.php "action=award.present&key=speed-4" | check_success
curl_get "action.php?query=award.current" | expect_count '<award ' 0
curl_post action.php "action=award.present&key=speed-1-1" | check_success
curl_get "action.php?query=award.current" | expect_one Felton
curl_post action.php "action=award.present&key=speed-2-1" | check_success
curl_get "action.php?query=award.current" | expect_count '<award ' 0


# Generate a next round of top 3, where there's a tie for third -- take 4 finalists
curl_post action.php "action=roster.new&roundid=1&top=3" | check_success
if [ "`grep -c '<finalist' $DEBUG_CURL`" -ne 4 ]; then
    test_fails Expecting 4 finalists
fi

curl_post action.php "action=schedule.generate&roundid=6" | check_success
# Racing for roundid=6: 4 heats
curl_post action.php "action=heat.select&roundid=6&now_racing=1" | check_success

staged_heat4 111 141 121 101
run_heat_place 6 1   2 3 4 1
staged_heat4 101 111 141 121
run_heat_place 6 2   3 4 1 2
staged_heat4 121 101 111 141
run_heat_place 6 3   4 1 2 3
staged_heat4 141 121 101 111
run_heat_place 6 4   1 2 3 4  x

# Usage: curl_text standings.php | for_roundid 1 | ...
function for_roundid() {
    grep "<tr.* data-roundid=.$1. "
}

ROUND1_TMP=`mktemp`

curl_text "standings.php" | for_roundid 1 > $ROUND1_TMP
cat $ROUND1_TMP | expect_count '<tr ' 5

cat $ROUND1_TMP | expect_one Carroll
cat $ROUND1_TMP | grep Carroll | expect_one "<div class=.inround.>1</div>"
cat $ROUND1_TMP | grep Carroll | expect_one "<td class=.col-insuper.></td>"

cat $ROUND1_TMP | expect_one Asher
cat $ROUND1_TMP | grep Asher | expect_one "<div class=.inround.>2</div>"
cat $ROUND1_TMP | grep Asher | expect_one "<td class=.col-insuper.></td>"

cat $ROUND1_TMP | expect_one Derick
cat $ROUND1_TMP | grep Derick | expect_one "<div class=.inround.>T3</div>"
cat $ROUND1_TMP | grep Derick | expect_one "<td class=.col-insuper.></td>"

cat $ROUND1_TMP | expect_one Jesse
cat $ROUND1_TMP | grep Jesse | expect_one "<div class=.inround.>T3</div>"
cat $ROUND1_TMP | grep Jesse | expect_one "<td class=.col-insuper.></td>"

cat $ROUND1_TMP | expect_one Felton
cat $ROUND1_TMP | grep Felton | expect_one "<div class=.inround.>5</div>"
cat $ROUND1_TMP | grep Felton | expect_one "<td class=.col-insuper.></td>"

rm $ROUND1_TMP

curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '[1,"111","Carroll Cybulski","Vroom","Lions \u0026 Tigers",1,1,"4","16","1st","1st"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '[2,"101","Adolfo \"Dolf\" Asher","","Lions \u0026 Tigers",2,2,"4","12","1st","3rd"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '["T3","121","Derick Dreier","","Lions \u0026 Tigers","T3","T3","4","9","2nd","3rd"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '["T3","141","Jesse Jara","","Lions \u0026 Tigers","T3","T3","4","9","2nd","4th"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '[5,"131","Felton Fouche","","Lions \u0026 Tigers",5,5,"4","4","4th","4th"]'

ROUND6_TMP=`mktemp`
curl_text "standings.php" | for_roundid 6 > $ROUND6_TMP

cat $ROUND6_TMP | expect_count '<tr ' 4

cat $ROUND6_TMP | expect_one Asher
cat $ROUND6_TMP | grep Asher | expect_one "<div class=.inround.>T1</div>"
cat $ROUND6_TMP | grep Asher | expect_one "<td class=.col-ingroup.>T1</td>"
cat $ROUND6_TMP | grep Asher | expect_one "<div class=.insuper.>T1</div>"
cat $ROUND6_TMP | grep Asher | expect_one "<td class=.col-insuper.>T1</td>"

cat $ROUND6_TMP | expect_one Jesse
cat $ROUND6_TMP | grep Jesse | expect_one "<div class=.inround.>T1</div>"
cat $ROUND6_TMP | grep Jesse | expect_one "<td class=.col-ingroup.>T1</td>"
cat $ROUND6_TMP | grep Jesse | expect_one "<div class=.insuper.>T1</div>"
cat $ROUND6_TMP | grep Jesse | expect_one "<td class=.col-insuper.>T1</td>"

cat $ROUND6_TMP | expect_one Carroll
cat $ROUND6_TMP | grep Carroll | expect_one "<div class=.inround.>T3</div>"
cat $ROUND6_TMP | grep Carroll | expect_one "<td class=.col-ingroup.>T3</td>"
cat $ROUND6_TMP | grep Carroll | expect_one "<div class=.insuper.>T3</div>"
cat $ROUND6_TMP | grep Carroll | expect_one "<td class=.col-insuper.>T3</td>"

cat $ROUND6_TMP | expect_one Derick
cat $ROUND6_TMP | grep Derick | expect_one "<div class=.inround.>T3</div>"
cat $ROUND6_TMP | grep Derick | expect_one "<td class=.col-ingroup.>T3</td>"
cat $ROUND6_TMP | grep Derick | expect_one "<div class=.insuper.>T3</div>"
cat $ROUND6_TMP | grep Derick | expect_one "<td class=.col-insuper.>T3</td>"

rm $ROUND6_TMP

curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '["T1","101","Adolfo \"Dolf\" Asher","","Lions \u0026 Tigers","T1","4","12","1st","3rd"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '["T1","141","Jesse Jara","","Lions \u0026 Tigers","T1","4","12","1st","3rd"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '["T3","111","Carroll Cybulski","Vroom","Lions \u0026 Tigers","T3","4","8","2nd","4th"]'
curl_text "export.php" | sed -n -e '/START_JSON/,/END_JSON/ p' | tail -2 | head -1 | \
    expect_one '["T3","121","Derick Dreier","","Lions \u0026 Tigers","T3","4","8","2nd","4th"]'
