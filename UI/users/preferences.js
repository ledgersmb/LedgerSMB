
var r;

require(['dojo/request'],
	function(request) {
	    r = request;
	});

function submit_form() {
    var do_submit = true;
    var login = document.prefs.username.value;
    var old_password = document.prefs.old_password.value;
    var new_password = document.prefs.new_password.value;
    var confirm_pass = document.prefs.confirm_password.value;

    if (old_password != "" && new_password != "" && confirm_pass != "") {
		  r('user.pl',
			 {
				  'data': {
						'action': 'change_password',
						'old_password': old_password,
						'new_password': new_password,
						'confirm_password': confirm_pass
				  },
				  'method': 'POST',
				  'sync': true
			 }).otherwise(function(err) {
				  // error branch of the response; can't see 200 here
				  var status = err.response.status;
				  if (status != '454'){
  						alert("Access Denied:  Bad username/Password ("+status+")");
				  } else {
                  alert('Company does not exist.');
				  }
				  do_submit = false;
			 });
        
		  if (do_submit) {
				r('login.pl',
				  {
						'data': {
							 'action': 'authenticate',
							 'company': document.prefs.company.value,
						},
						'user': login,
						'password': new_password,
						'sync': true,
						'method': 'POST'
				  }).then(function(res) {
						document.prefs.old_password.value = '';
						document.prefs.new_password.value = '';
						document.prefs.confirm_password.value = '';
              });
		  }
    }
	 require(['dojo/dom-form'],function(f) {
		  if (do_submit) {
				r('',
				  {
						'data': f.toQuery('prefs'),
						'method': 'POST'
				  });
		  }
	 });
    
    return false;
}

