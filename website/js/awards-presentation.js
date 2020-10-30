// Requires dashboard-ajax.js

function update_awards_selection() {
  $("li").addClass("hidden");
  $("tr.headings").removeClass("hidden");

  var awardtypeid = $("#awardtype-select").find("option:selected").data('awardtypeid');
  var group = $("#group-select").find("option:selected");
  // data-supergroup is present on the supergroup choice; its value is irrelevant
  var supergroup = group.data('supergroup');
  var classid = group.data('classid');
  var rankid = group.data('rankid');

  var selector = "li";
  if (awardtypeid != null) {
    selector += "[data-awardtypeid='" + awardtypeid + "']";
  }
  if (supergroup != null) {
    selector += "[data-classid='0'][data-rankid='0']";
  } else {
    if (classid != null) {
      selector += "[data-classid='" + classid + "']";
    }
    if (rankid != null) {
      selector += "[data-rankid='" + rankid + "']";
    }
  }

  $(selector).removeClass("hidden");
}

var g_changing_awards = false;

function on_choose_award(list_item) {
  var item = $(list_item);
  $.ajax(g_action_url,
         {type: 'POST',
          data: {action: 'award.present',
                 key: item.data('awardkey'),
                 reveal: '0'}
         });
  $("#awardname").text(item.data('awardname'));
  $("#recipient").text(item.data('recipient'));
  $("#carnumber").text('Car number ' + item.data('carnumber'));
  $("#carname").text(item.data('carname'));
  $("#classname").text(item.data('class'));
  $("#rankname").text(item.data('rank'));
  $(".presenter-inner").removeClass('hidden');
  $("#kiosk-summary").addClass('hidden');
  $("#reveal-checkbox").prop('checked', false);
  g_changing_awards = true;
  try {
    $("#reveal-checkbox").trigger("change", true);
  } finally {
    g_changing_awards = false;
  }
}

function on_reveal() {
  if (!g_changing_awards) {
    $.ajax(g_action_url,
           {type: 'POST',
            data: {action: 'award.present',
                   reveal: $("#reveal-checkbox").prop('checked') ? 1 : 0}
           });
  }
}

function on_clear_awards() {
  $.ajax(g_action_url,
         {type: 'POST',
          data: {action: 'award.present',
                 key: '',
                 reveal: '0'}
         });
  $("#awardname").text('');
  $("#recipient").text('');
  $("#carnumber").text('');
  $("#carname").text('');
  $("#classname").text('');
  $("#rankname").text('');
  $(".presenter-inner").addClass('hidden');
  $("#kiosk-summary").addClass('hidden');
}

function parse_award(data) {
  var award_xml = data.getElementsByTagName('award')[0];
  if (!award_xml) {
    return false;
  }
  return {key: award_xml.getAttribute('key'),
          reveal: award_xml.getAttribute('reveal') == 'true',
          awardname: award_xml.getAttribute('awardname'),
          carnumber: award_xml.getAttribute('carnumber'),
          carname: award_xml.getAttribute('carname'),
          firstname: award_xml.getAttribute('firstname'),
          lastname: award_xml.getAttribute('lastname'),
          classname: award_xml.getAttribute('classname'),
          subgroup: award_xml.getAttribute('subgroup'),
          headphoto: award_xml.getAttribute('headphoto'),
          carphoto: award_xml.getAttribute('carphoto')};
}

function initialize_award_controls() {
  $.ajax(g_action_url,
         {type: 'GET',
          data: {query: 'award.current'},
          success: function(data) {
            var award = parse_award(data);
            if (!award) {
              $("#rankname").text('');
              award = {key: '',
                       reveal: false,
                       awardname: '',
                       carnumber: '',
                       carname: '',
                       firstname: '',
                       lastname: '',
                       classname: '',
                       subgroup: '',
                       headphoto: '',
                       carphoto: ''};
            } else {
              $(".presenter-inner").removeClass('hidden');
            }
            $("#awardname").text(award['awardname']);
            $("#recipient").text(award['firstname'] + ' ' + award['lastname']);
            $("#carnumber").text(award['carnumber'] ? 'Car number ' + award['carnumber'] : '');
            $("#carname").text(award['carname']);
            $("#classname").text(award['classname']);
            if (award['subgroup'] && award['subgroup'].length > 0) {
              $("#rankname").text(award['subgroup']);
            }
            $("#kiosk-summary").addClass('hidden');
            $("#reveal-checkbox").prop('checked', award['reveal']);
            g_changing_awards = true;
            try {
              $("#reveal-checkbox").trigger("change", true);
            } finally {
              g_changing_awards = false;
            }
          },
         });
}

$(function () {
    $("#awardtype-select").on("change", function(event) {
        update_awards_selection();
      });
    $("#group-select").on("change", function(event) {
        update_awards_selection();
      });
  $("input[name='now-presenting'][type='radio']").on("change", function(event) {
    // 'this' will be the now-selected radio element
    AwardRadio.onchange(this); });

  initialize_award_controls();
  setInterval(function() { initialize_award_controls(); }, 1000);
});
