'use strict';

function on_edit_class(event) {
  var list_item = $(event.target).closest("li");
  var classid = list_item.attr('data-classid');

  // list_item is an <li> from #edit_all_classes_modal.  We expect it to have a
  // .class-name span child, plus data attributes for classid, count, and nrounds.

  // list_item's top paragraph still includes spans and inputs; this recovers just the class name text
  var class_name = list_item.children("p").clone().find('span').remove().end().text();

  $("#edit_class_name").val(class_name);
  $("#edit_class_name").attr('data-classid', classid);
  var ntrophies = list_item.attr('data-ntrophies');
  $("#edit_class_ntrophies option").prop('selected', false);
  if (ntrophies < 0) {
    $("#edit_class_ntrophies option[value='-1']").prop('selected', true)
  } else {
    $('#edit_class_ntrophies option')
      .filter(function () { return $(this).text() == ntrophies; })
      .prop('selected', true);
  }
  mobile_select_refresh($('#edit_class_ntrophies'));

  // The "completed rounds" message appears only if there are no native racers,
  // but there are some completed rounds that prevent offering deletion of the
  // class.
  var count = list_item.attr('data-count');
  var nrounds = list_item.attr('data-nrounds');
  $("#completed_rounds_extension").toggleClass('hidden', !(count == 0 && nrounds != 0));
  $("#completed_rounds_count").text(nrounds);

  var constituent_of = list_item.is('[data-constituent-of]') ? list_item.attr('data-constituent-of') : '';
  $("#constituent_extension").toggleClass('hidden', constituent_of == '');
  $("#constituent_owner").text(constituent_of);

  $("#delete_class_extension").toggleClass('hidden', !(count == 0 && nrounds == 0 && constituent_of == ''));
  show_modal("#edit_one_class_modal", function () {
    $.ajax(g_action_url,
           {type: 'POST',
            data: {action: 'class.edit',
                   classid: list_item.attr('data-classid'),
                   name: $("#edit_class_name").val(),
                   ntrophies: $("#edit_class_ntrophies").val()},
            success: function () {
              poll_for_structure();
            }});

    close_edit_one_class_modal();
    return false;
  });
}

function close_edit_one_class_modal() {
  close_modal("#edit_one_class_modal");
}

function handle_delete_class() {
  close_edit_one_class_modal();
  if (confirm('Really delete ' + group_label_lc()
              + ' "' + $('#edit_one_class_modal input[name="name"]').val() + '"?')) {
    $.ajax(g_action_url,
           {type: 'POST',
            data: {action: 'class.delete',
                   classid: $("#edit_class_name").attr('data-classid')
                  },
            success: function(data) {
              poll_for_structure();
            }
           });
  }
  return false;
}


function on_edit_rank(event) {
  var list_item = $(event.target).closest("li");
  $("#edit_rank_name").attr('data-rankid', list_item.attr('data-rankid'));

  var rank_name = list_item.children("p").clone().find('span').remove().end().text();
  $("#edit_rank_name").val(rank_name);

  // True if we're the only rank for this class:
  var only_rank = list_item.closest("ul.subgroups").find("li.subgroup").length == 1;
  var count = list_item.attr('data-count');
  $("#delete_rank_extension").toggleClass('hidden', only_rank || (count > 0));
  var classid = list_item.closest("ul").attr('data-classid');
  $("#edit_rank_name").attr('data-classid', classid);
  show_modal("#edit_one_rank_modal", function() {
    $.ajax(g_action_url,
           {type: 'POST',
            data: {action: 'rank.edit',
                   rankid: list_item.attr('data-rankid'),
                   name: $("#edit_rank_name").val()},
            success: function(data) {
              poll_for_structure();
            }});

    close_edit_one_rank_modal();
    return false;
  });
}

function close_edit_one_rank_modal() {
  close_modal("#edit_one_rank_modal");
}

function handle_delete_rank() {
  var classid = $("#edit_rank_name").attr('data-classid');
  close_edit_one_rank_modal();
  if (confirm('Really delete ' + subgroup_label_lc()
              + ' "' + $("#edit_rank_name").val() + '"?')) {
    $.ajax(g_action_url,
           {type: 'POST',
            data: {action: 'rank.delete',
                   rankid: $("#edit_rank_name").attr('data-rankid')
                  },
            success: function(data) {
              repopulate_class_list(data);
              repopulate_constituent_classes(data);
              hide_ranks_except(classid);
            }
           });
  }
  return false;
}
