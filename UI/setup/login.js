function submit_form() {
	 require(['dojo/request/xhr','dojo/dom', 'dojo/dom-style'],
				function(xhr,dom,style){

					 var username = document.getElementsByName('s_user')[0].value;
					 var password = document.getElementsByName('s_password')[0].value;
					 var company = document.getElementsByName('database')[0].value;

		  xhr('login.pl?action=authenticate&company=postgres&dbonly=1',
				{
					 user: username,
					 password: password
				}).then(function(data){
					 window.location.href="setup.pl?action=login&database="+company;
				}, function(err) {
					 var status = err.response.status;
					 if (status == '454'){
						  alert('Company does not exist.');
					 } else {
						  alert('Access denied ('+status+'): Bad username/password');
					 }
				});
	 });
	 return false;
}

