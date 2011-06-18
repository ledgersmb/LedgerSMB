
function submit_form() {
	var http = get_http_request_object();
	var login = document.prefs.username.value;
	var old_password = document.prefs.old_password.value;
	var new_password = document.prefs.new_password.value;
	var confirm_pass = document.prefs.confirm_password.value;
	http.open("get", 'user.pl?action=change_password' +
                          '&old_password='+old_password+
                          '&new_password='+new_password+
                          '&confirm_password='+ confirm_pass,
                          false, login, old_password);
	http.send("");
        if (http.status != 200){
                if (http.status != '454'){
  		     alert("Access Denied:  Bad username/Password");
                } else {
                     alert('Company does not exist.');
                }
		return false;
	}
    http.open("get", "login.pl?action=authenticate", false, 
		login, new_password
    );
    if (http.status == 200){
       document.pref.old_password.value = '';
       document.pref.new_password.value = '';
       document.pref.confirm_password.value = '';
    }
    return true;
}

