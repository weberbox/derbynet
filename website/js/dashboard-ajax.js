// Common ajax-handling functions for dashboard-like pages.  Looks for <reload/>
// elements to reload the page, and reports errors or failures via alerts.

g_action_url = "action.php";

// This variable gets set to true when leaving a page; it should prevent errors from
// showing for any in-flight ajax calls.
var g_unloading = false;

$(window).bind("beforeunload", function() { g_unloading = true; });

// Note that this doesn't run if the $.ajax call has a 'success:' callback that
// generates an error.
$(document).ajaxSuccess(function(event, xhr, options, xmldoc) {
  var fail = xmldoc.documentElement.getElementsByTagName("failure");
  if (fail && fail.length > 0) {
    console.log(xmldoc);
    alert("Action failed: " + fail[0].textContent);
  }
});

// <reload/> element
$(document).ajaxSuccess(function(event, xhr, options, xmldoc) {
	var reload = xmldoc.documentElement.getElementsByTagName("reload");
	if (reload && reload.length > 0) {
        console.log('ajaxSuccess event: reloading page');
		location.reload(true);
	}
});

$(document).ajaxError(function(event, jqXHR, ajaxSettings, thrownError) {
  if (!g_unloading) {
    console.log("ajaxError: " + thrownError);
    console.log(thrownError);
    console.log(jqXHR);
    console.log("Response text: " + jqXHR.responseText);
    console.log("ReadyState: " + jqXHR.readyState);
    console.log("status: " + jqXHR.status);
    console.log(event);
	alert("Ajax error: " + thrownError);
  }
});

