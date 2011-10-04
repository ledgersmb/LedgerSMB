function submit_form() {
	var http = get_http_request_object();
    var username = document.login.login.value;
	var password = document.login.password.value;
	http.open("get", 'login.pl?action=authenticate&company='
		+ document.login.company.value, false, 
		username, password);
	http.send("");
        if (http.status != 200){
                if (http.status != '454'){
  		     alert("Access Denied:  Bad username/Password");
                } else {
                     alert('Company does not exist.');
                }
		return false;
	}
	document.location = document.login.action + "?action=login&company="+
		document.login.company.value;
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

function setup_page(login_label, password_label) {
	var credential_html;

	var cred_div = document.getElementById("credentials");
	credential_html = 
		'<div class="labelledinput">' +
			'<div class="label">' +
				'<label for="login">' +
				login_label+
				":</label>" +
			'</div>' +
			'<div class="input">' +
				'<input class="login" ' + 
				'name="login" size="30" ' + 
				'value="" id="login" '+ 
				'accesskey="n" />' +
			'</div>' +
		'</div>' +
		'<div class="labelledinput">' +
			'<div class="label">' +
				'<label for="password">' +
				password_label +
				':</label>' +
			'</div>' +
			'<div class="input">' +
				'<input class="login" ' + 
					'type="password" ' +
					'name="password" ' +
					'size="30" ' +
					'id="password" ' +
					'accesskey="p" />' +
			'</div>' +
		'</div>';
	if (!document.login.blacklisted.value && get_http_request_object()){
		cred_div.innerHTML = credential_html;
		document.login.login.focus();
	}
	else {
		document.login.company.focus();
	}
}
