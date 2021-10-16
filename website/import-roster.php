<?php @session_start();

require_once('inc/data.inc');
require_once('inc/authorize.inc');
require_once('inc/divisions.inc');
require_once('inc/plural.inc');
require_permission(SET_UP_PERMISSION);

require_once('inc/import-csv.inc');

try {
  $divisions = all_divisions();
} catch (PDOException $p) {
  $divisions = [];
}

class ImportRoster extends ImportCsvGenerator {
  protected function make_state_of_play_div() {
    global $divisions;

    try {
      $nracers = read_single_value("SELECT COUNT(*) FROM RegistrationInfo", array());
    } catch (PDOException $p) {
      $nracers = -1;
    }
  ?>
    <div id="state-of-play" class="<?php echo $nracers <= 0 ? 'hidden' : ''; ?>">
      <div id="file-stats" class="hidden">
        <span id="file-name">File</span>
        contains <span id="file-racer-count">0</span>
        racers<span id='file-class-count-and-label'>,
        <a id="class-counts-button" href="#">
          <span id="file-class-count"></span>
          <span id="file-division-label"><?php echo division_label_pl_lc(); ?></span>
          (<span id='file-class-new-count'></span> new)</a></span>.
      </div>
      <?php
         if ($nracers > 0) {
           $n_divisions = count($divisions);
           $label = $n_divisions == 1 ? division_label_lc() : division_label_pl_lc();
           echo "There are already ".$nracers." racer(s) and ".$n_divisions
               ." <span id='existing-division-label'>".$label."</span> in the database.";
         }
      ?>
   </div><!--- state-of-play -->
  <?php
  }

  protected function make_relabeling_section() {
    ?>
    <label for="division-label">A division is called a(n):</label>
     <input id="division-label" name="division-label" type="text" class="not-mobile"
            value="<?php echo division_label(); ?>"/>
    <?php
  }
}
?><!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<title>Import Roster</title>
<?php make_head_matter_for_import_page(); ?>
<link rel="stylesheet" type="text/css" href="css/import-roster.css"/>
<script type="text/javascript" src="js/modal.js"></script>
<script type="text/javascript" src="js/plural.js"></script>
<script type="text/javascript" src="js/import-roster.js"></script>
</head>
<script type="text/javascript">
function all_divisions() {
  return <?php echo json_encode($divisions, JSON_HEX_TAG | JSON_HEX_AMP | JSON_PRETTY_PRINT); ?>;
}
</script>
<body>
<?php
  make_banner('Import Roster', 'setup.php');
  $page_maker = new ImportRoster;
  $page_maker->make_import_csv_div('Import Roster',
                                   array(
                                     array(
                                       'lastname' => array('name' => "Last Name",
                                                           'required' => true),
                                       'firstname' => array('name' => "First Name",
                                                            'required' => true),
                                       'division' => array('name' => division_label(),
                                                           'required' => false),
                                       'carnumber' => array('name' => "Car Number",
                                                            'required' => false),
                                       'carname' => array('name' => "Car Name",
                                                          'required' => false),
                                       'exclude' => array('name' => 'Exclude?',
                                                          'required' => false)),
                                     array(
                                       'first-last' => array('name' => 'First & Last Name',
                                                             'required' => true,
                                                             'span' => 2),
                                       1 => array('span' => 4)),
                                     ));
?>
<div id="new_divisions_modal" class="modal_dialog block_buttons hidden">
  <div id="existing_divisions_div">
  </div>
  <div id="new_divisions_div">
  </div>
  <form>
    <input type="button" value="Dismiss" onclick='close_modal("#new_divisions_modal");'/>
  </form>
</div>
<div class="footer">Or instead: <a href="import-results.php">Import results exported from another race...</a></div>
<?php
  require_once('inc/ajax-pending.inc');
?>
</body>
</html>
