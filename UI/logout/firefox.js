try{
var agt=navigator.userAgent.toLowerCase();
if (agt.indexOf("firefox") != -1) {
	var xhre = new XMLHttpRequest() ;
        xhre.open("GET",window.location,true,"logout","logout");
        xhre.send("");
        xhre.abort();
        window.alert('success');
}
}
catch (e) {
}
