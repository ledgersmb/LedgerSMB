/* construct_form_node(query, cls, registry,
 *                     textbox, checkbox, radio, select, button, textarea,
 *                     input)
 * This constructs the appropriate dojo/dijit object from the input provided and
 * returns it to the calling function.  query and cls are needed for select box
 * and textbox class detection.  input is the node.  The others are appropriate
 * dijit/dojo classes for the widgets.
 */
/*

/* Set up form.tabular forms.  
 * Supports the following additional classes for setting columns
 * cols-1
 * cols-2
 * cols-3
 *
 * Normally tabular will attach to the form element in most simple forms, but
 * for more complex ones, you can use div instead.
 *
 * Also sets up textboxes, checkboxes, and date pickers in the forms.
 *
 * As of first commit only setting up table containers.
 */

require(['lsmb/lib/Loader', 'dojo/cookie', 'dojo/domReady!'],
function(l){
    if (location.search.indexOf('&dojo=no') != -1) {
        dojo.cookie("lsmb-dojo-disable", "yes", {});
    } else if (location.search.indexOf('&dojo') != -1) {
        dojo.cookie("lsmb-dojo-disable", "no", {});
    }

    if (dojo.cookie("lsmb-dojo-disable") != 'yes') {
        loader = new l;
        loader.setup();
    } else {
        init();
    }
});
