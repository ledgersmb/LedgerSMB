/** @format */

require([
   "dojo/request/xhr",
   "dojo/dom",
   "dojo/dom-style",
   "dojo/json",
   "dijit/Dialog",
   "dijit/ProgressBar",
   "dojo/domReady!"
], function (xhr, dom, domStyle, json, dialog, progressBar) {
   // Make indicator visible
   function showIndicator() {
      domStyle.set(dom.byId("login-indicator"), "visibility", "visible");
   }

   // Send login data
   function sendForm() {
      var username = document.login.login.value;
      var password = document.login.password.value;
      var company = encodeURIComponent(document.login.company.value);

      xhr("login.pl?action=authenticate&company=" + company, {
         method: "POST",
         headers: { "Content-Type": "application/json" },
         handleAs: "json",
         data: json.stringify({
            login: username,
            password: password,
            company: company
         })
      }).then(
         function (data) {
            window.location.href = data.target;
         },
         function (err) {
            var status = err.response.status;
            if (status === 454) {
               new dialog({
                  title: "Error",
                  content: "Company does not exist.",
                  style: "width: 300px"
               }).show();
            } else if (
               status === 400 &&
               err.response.text === "Credentials invalid or session expired"
            ) {
               new dialog({
                  title: "Error",
                  content: "Access denied: Bad username/password",
                  style: "width: 300px"
               }).show();
            } else if (status === 521) {
               new dialog({
                  title: "Error",
                  content: "Database version mismatch",
                  style: "width: 300px"
               }).show();
            } else {
               new dialog({
                  title: "Error",
                  content: "Unknown error preventing login",
                  style: "width: 300px"
               }).show();
            }
            domStyle.set(dom.byId("login-indicator"), "visibility", "hidden");
         }
      );
   }

   // Set-up progress bar
   function setIndicator() {
      var indicator = new progressBar({
         id: "login-progressbar",
         value: 100,
         indeterminate: true
      }).placeAt("login-indicator", "only");
      indicator.startup();
   }

   // Submit form and show a 10 seconds progress bar
   function submitForm() {
      showIndicator();
      window.setTimeout(showIndicator, 0);
      window.setTimeout(sendForm, 10);
      return false;
   }

   setIndicator();
   // Make it public
   window.submitForm = submitForm;
});
