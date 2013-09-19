

function show_indicator() {
        var e = document.getElementById('indicator');
        e.style.visibility='visible';
}

function submit_form() {
        window.setTimeout(show_indicator, 0);
        window.setTimeout(send_form, 10);
        return false;
}

function send_form() {
	var http = get_http_request_object();
    var username = document.login.login.value;
	var password = document.login.password.value;
	var company = document.login.company.value;
	var action = document.login.action.value;
        //alert('document.login.company.value='+document.login.company.value);
	http.open("get", 'login.pl?action=authenticate&company='+company, false, username, password);
	http.send("");
        if (http.status != 200){
                if (http.status != '454'){
  		     alert("Access Denied:  Bad username/Password");
                } else {
                     alert('Company does not exist.');
                }
		return false;
	}
	document.location=document.login.action.value+".pl?action=login&company="+document.login.company.value;
}

function check_auth() {
    
    var http = get_http_request_object();
    var username = "admin";
    var password = document.login.password.value;
    
    http.open("get", "login.pl?action=authenticate&company="
        + document.login.company.value, false, 
		username, password
    );
}

