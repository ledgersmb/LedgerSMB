function submit_form() {
	var http = get_http_request_object();
        var username = document.getElementById('s-user').value;
	var password = document.getElementById('s-password').value;
	http.open("get", 'login.pl?action=authenticate&company=template1',
		false, username, password);
	http.send("");
        if (http.status != 200){
                if (http.status != '454'){
  		     alert("Access Denied:  Bad username/Password");
                } else {
                     alert('Company does not exist.');
                }
		return false;
	}
	document.location = "setup.pl?action=login&company="+
		document.credentials.database.value;
}

function init() {
    document.getElementById('userpass').style.display = 'block';
    document.getElementById('loginform').addEventListener('submit', 
           function () {submit_form()}, false);
}
