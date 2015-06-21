function submit_form() {
	 require(['dojo/request/xhr','dojo/dom', 'dojo/dom-style'],
				function(xhr,dom,style){

					 var username = dom.byId('s_user').value;
					 var password = dom.byId('s_password').value;
					 var company = document.login_form.company.value;
					 var action = document.login_form.action.value;

		  xhr('login.pl?action=authenticate&company=postgres',
				{
					 user: username,
					 password: password
				}).then(function(data){
					 window.location.href=action
						  +".pl?action=login&company="+company;
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

