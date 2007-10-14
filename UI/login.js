// Note: we do not heed to try other interfaces since we don't support IE 6 or
// lower.  If we need to support other interfaces later, we can add them.
// --CT
function get_http_request_object(){
	if (typeof XMLHttpRequest == undefined){
		return false;
	} else {
		return new XMLHttpRequest();
	}
}

function submit_form() {
	var http = get_http_request_object();
        var username = document.login.login.value;
	var password = document.login.password.value;
	http.open("get", 'login.pl?action=authenticate&company='
		+ document.login.company.value, false, 
		username, password);
	http.send("");
	alert(http.status);
        if (http.status != 200){
		alert("Access Denied:  Bad username/Password");
		return false;
	}
	document.location = document.login.action + "?action=login&company="+
		documnet.login.company.value;
}
