

function show_indicator() {
	 require(['dojo/dom','dojo/dom-style'],
				function(dom,style) {
					 style.set(dom.byId('login-indicator'),'visibility','visible');
				});
}

function submit_form() {
        window.setTimeout(show_indicator, 0);
        window.setTimeout(send_form, 10);
        return false;
}

function send_form() {
    var username = document.login.login.value;
	 var password = document.login.password.value;
	 var company = document.login.company.value;
	 var action = document.login.action.value;

	 require(['dojo/request/xhr','dojo/dom', 'dojo/dom-style'],
				function(xhr,dom,style){
		  xhr('login.pl?action=authenticate&company='+company,
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
					 style.set(dom.byId('login-indicator'),'visibility','hidden');
				});
	 });
}

require(['dojo/dom-construct', 'dijit/ProgressBar', 'dojo/domReady!'],
		  function(construct, progressbar){
				var indicator = new progressbar({
                "style": "width: 10em",
                "id": "login-progressbar",
                "value": 100,
                "indeterminate": true
				}).placeAt("login-indicator", "only");
				indicator.startup();   
		  });


