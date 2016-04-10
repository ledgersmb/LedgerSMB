

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

	 require(['dojo/request/xhr','dojo/dom', 'dojo/dom-style',
             'dijit/Dialog'],
				function(xhr,dom,style,Dialog){
		  xhr('login.pl?action=authenticate&company='+company,
				{
					 user: username,
					 password: password
				}).then(function(data){
					 window.location.href=action
                                           + ".pl?action=login&company=" + company;
				}, function(err) {
					 var status = err.response.status;
					 if (status == '454'){
                    (new Dialog({ title: 'Error',
                                  content: 'Company does not exist.',
                                  style: 'width: 300px',
                                })).show();
					 } else if (status == '401') {
                    (new Dialog({ title: 'Error',
                                  content: 'Access denied: Bad username/password',
                                  style: 'width: 300px',
                                })).show();
					 } else if (status == '521') {
                    (new Dialog({ title: 'Error',
                                  content: 'Database version mismatch',
                                  style: 'width: 300px',
                                })).show();
                } else {
                    (new Dialog({ title: 'Error',
                                  content: 'Unknown error preventing login',
                                  style: 'width: 300px',
                                })).show();
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


