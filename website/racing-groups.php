<?php @session_start();
require_once('inc/data.inc');
require_once('inc/classes.inc');
require_once('inc/banner.inc');
require_once('inc/authorize.inc');
require_once('inc/divisions.inc');
require_once('inc/schema_version.inc');
require_permission(SET_UP_PERMISSION);

if (schema_version() < DIVISION_SCHEMA) {
  header('Location: setup.php');
  exit(0);
}


?><!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<title>Racing Groups Editor</title>
<?php require('inc/stylesheet.inc'); ?>
<script type="text/javascript" src="js/jquery.js"></script>
<script type="text/javascript" src="js/jquery-ui.min.js"></script>
<script type="text/javascript" src="js/ajax-setup.js"></script>
<script type="text/javascript" src="js/jquery.ui.touch-punch.min.js"></script>
<script type="text/javascript" src="js/dashboard-ajax.js"></script>
<script type="text/javascript" src="js/mobile.js"></script>
<script type="text/javascript" src="js/modal.js"></script>
<script type="text/javascript" src="js/racing-groups.js"></script>
<script type="text/javascript" src="js/racing-groups-add-group.js"></script>
<script type="text/javascript" src="js/racing-groups-edit.js"></script>
<script type="text/javascript">
function use_subgroups() { return <?php echo json_encode(use_subgroups()); ?>; }
function group_label() { return <?php echo json_encode(group_label()); ?>; }
function group_label_plural() { return <?php echo json_encode(plural(group_label())); ?>; }
function group_label_lc() { return <?php echo json_encode(group_label_lc()); ?>; }
function subgroup_label() { return <?php echo json_encode(subgroup_label()); ?>; }
function subgroup_label_plural() { return <?php echo json_encode(plural(subgroup_label())); ?>; }
function subgroup_label_lc() { return <?php echo json_encode(subgroup_label_lc()); ?>; }

$(function() {
    var rule = <?php echo json_encode(group_formation_rule()); ?>;
    $("input[name='form-groups-by'][value='" + rule + "']").prop('checked', true);
    mobile_radio_refresh($("input[name='form-groups-by']"));
  });
</script>
<link rel="stylesheet" type="text/css" href="css/mobile.css"/>
<link rel="stylesheet" type="text/css" href="css/racing-groups.css"/>
</head>
<body>
<?php make_banner('Racing Groups', 'setup.php'); ?>

<div id="below-banner">

<div id="race-rules">

<?php if (read_single_value('SELECT COUNT(*) FROM Divisions') > 1) { ?>
  <input id="by-division-radio" type="radio" name="form-groups-by" value="by-division"/>
   <label for="by-division-radio">Race each <?php echo division_label_lc(); ?> as a group</label>
<?php } ?>

<input id="one-group-radio" type="radio" name="form-groups-by" value="one-group"/>
<label for="one-group-radio">Race as one big group</label>

<input id="custom-group-radio" type="radio" name="form-groups-by" value="custom"/>
<label for="custom-group-radio">Custom racing groups</label>

<div class="switch">
<label for="use-subgroups">Use Subgroups?</label>
<input id="use-subgroups" type="checkbox" class="flipswitch"
     data-on-text="Yes" data-off-text="No"
       <?php if (use_subgroups()) echo "checked=\"checked\""; ?>/>
</div>

<div class="switch">
<label for="cleanup">Remove unpopulated groups and subgroups?</label>
<input id="cleanup" type="checkbox" class="flipswitch"
     data-on-text="Yes" data-off-text="No"
       <?php if (true) echo "checked=\"checked\""; ?>/>
</div>

<div style="margin-top: 10px;">
  <ul id="aggregate-groups" class="mlistview">
  </ul>
</div>

<div class="block_buttons">
  <input id="add-aggregate-button" type="button" value="Add Aggregate"/>
</div>

</div><!-- race-rules -->

<div id="race-structure">

<p class="instructions">Drag <span class="group-color">&nbsp;</span> groups
       <span class="and-subgroups">and <span class="subgroup-color">&nbsp;</span> subgroups</span>
       to re-order.</p>
       <p class="instructions">Drag <span class="division-color">&nbsp;</span> <?php echo division_label_pl_lc(); ?>
       onto <span class="group-color">&nbsp;</span> groups
        <span class="and-subgroups" style="white-space: nowrap;">and <span class="subgroup-color">&nbsp;</span> subgroups</span>.
</p>

<ul id="all-groups" class="mlistview">

  <li id='new-group' class='group'>
    <p>New Group</p>
  </li>
</ul>

</div><!-- race-structure -->

</div><!-- below-banner -->



<div id="add_class_modal" class="modal_dialog wide_modal hidden block_buttons">
  <form>
    <input type="hidden" name="action" value="class.add"/>

    <div id='aggregate-by-div' class="aggregate-only">
      <label for='aggregate-by-checkbox'>Aggregate by &nbsp;</label>
      <input id='aggregate-by-checkbox' type='checkbox' class='flipswitch'
            onchange='on_aggregate_by_change()'
            data-off-text="<?php echo group_label();?>"
            data-on-text="<?php echo subgroup_label();?>"/>
    </div>

    <h3>Add New <?php echo group_label(); ?></h3>
    <input id='add-class-name' name="name" type="text"/>

   <div class="ntrophies">
    <label for='add-class-ntrophies'>Number of speed trophies:</label>
    <select id='add-class-ntrophies' name="ntrophies">
      <option value="-1" selected="selected">Default</option>
      <option>0</option>
      <option>1</option>
      <option>2</option>
      <option>3</option>
      <option>4</option>
      <option>5</option>
      <option>6</option>
      <option>7</option>
      <option>8</option>
      <option>9</option>
      <option>10</option>
    </select>
   </div>

    <div id='constituent-clip' class='aggregate-only'>
      <div id='constituent-div'>
        <div id='constituent-classes'></div>
        <div id='constituent-subgroups'></div>
      </div>
    </div>

    <input type="submit"/>
    <input type="button" value="Cancel"
           onclick="close_add_class_modal();"/>
  </form>
</div>

<div id="edit_one_class_modal" class="modal_dialog hidden block_buttons">
  <form>
    <h3><?php echo group_label(); ?> Name</h3>
    <input id="edit_class_name" name="name" type="text"/>

   <div class="ntrophies">
    <label for='edit-class-ntrophies'>Number of speed&nbsp;trophies:</label>
    <select id='edit-class-ntrophies' name='ntrophies'>
      <option value="-1">Default</option>
      <option>0</option>
      <option>1</option>
      <option>2</option>
      <option>3</option>
      <option>4</option>
      <option>5</option>
      <option>6</option>
      <option>7</option>
      <option>8</option>
      <option>9</option>
      <option>10</option>
    </select>
</div>

    <div id="completed_rounds_extension">
      <p><span id="completed_rounds_count"></span> completed round(s) exist for this class.</p>
    </div>

    <div id="constituent_extension">
      <p>Constituent of <span id="constituent_owner"></span>, possibly other aggregates.</p>
    </div>

    <div id="edit_ranks_extension" class="hidden">
      <input type="button" value="Add <?php echo subgroup_label(); ?>"
             onclick="show_add_rank_modal();" />
      <br/>
    </div>

    <input type="submit"/>
    <input type="button" value="Cancel"
           onclick="close_edit_one_class_modal();"/>

    <div id="delete_class_extension">
    <input type="button" value="Delete <?php echo group_label(); ?>"
           class="delete_button"
           onclick="handle_delete_class();"/>
    </div>
  </form>
</div>

<div id="add_rank_modal" class="modal_dialog hidden block_buttons">
  <h3>Add New <?php echo subgroup_label(); ?></h3>
  <form>
    <input type="hidden" name="action" value="rank.add"/>
    <input type="hidden" name="classid"/>
    <input name="name" type="text"/>

    <input type="submit"/>
    <input type="button" value="Cancel"
           onclick="close_add_rank_modal();"/>
  </form>
</div>

<div id="edit_one_rank_modal" class="modal_dialog hidden block_buttons">
  <h3>New <?php echo subgroup_label(); ?> Name</h3>
  <form>
    <input id="edit_rank_name" name="name" type="text"/>

    <input type="submit"/>
    <input type="button" value="Cancel"
           onclick="close_edit_one_rank_modal();"/>

    <div id="delete_rank_extension">
    <input type="button" value="Delete <?php echo subgroup_label(); ?>"
           class="delete_button"
           onclick="handle_delete_rank();"/>
    </div>
  </form>
</div>

</body>
</html>