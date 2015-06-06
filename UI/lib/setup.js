
/* Note, this is the first code being executed. If we don't required
   the parser here, the "onLoad" parse event isn't going to fire. */
require(['lsmb/lib/Loader', 'dojo/cookie', 'dojo/parser',
	 'dojo/domReady!'],
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
