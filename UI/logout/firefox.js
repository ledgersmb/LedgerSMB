try{
var agt=navigator.userAgent.toLowerCase();
if (agt.indexOf("firefox") != -1) {
	var xhre = new XMLHttpRequest() ;
        xhre.open("GET",window.location,true,"logout","logout");
        xhre.send("");
        xhre.abort();
        //be aware, sometimes get-request reaches server despite abort.
        // LedgerSMB::Auth::DB::get_credentials can have $auth=logout:logout
}
}
catch (e) {
}
