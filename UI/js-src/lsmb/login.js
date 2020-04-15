/** @format */
/* eslint global-require:0, no-unused-vars:0 */ /* submitForm is used elsewhere */

function showIndicator() {
   require(["dojo/dom", "dojo/dom-style"], function (dom, style) {
      style.set(dom.byId("login-indicator"), "visibility", "visible");
   });
}

function sendForm() {
   var username = document.login.login.value;
   var password = document.login.password.value;
   var company = encodeURIComponent(document.login.company.value);

   require([
      "dojo/request/xhr",
      "dojo/dom",
      "dojo/dom-style",
      "dojo/json",
      "dijit/Dialog"
   ], function (xhr, dom, style, json, Dialog) {
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
               new Dialog({
                  title: "Error",
                  content: "Company does not exist.",
                  style: "width: 300px"
               }).show();
            } else if (
               status === 400 &&
               err.response.text === "Credentials invalid or session expired"
            ) {
               new Dialog({
                  title: "Error",
                  content: "Access denied: Bad username/password",
                  style: "width: 300px"
               }).show();
            } else if (status === 521) {
               new Dialog({
                  title: "Error",
                  content: "Database version mismatch",
                  style: "width: 300px"
               }).show();
            } else {
               new Dialog({
                  title: "Error",
                  content: "Unknown error preventing login",
                  style: "width: 300px"
               }).show();
            }
            style.set(dom.byId("login-indicator"), "visibility", "hidden");
         }
      );
   });
}

function submitForm() {
   window.setTimeout(showIndicator, 0);
   window.setTimeout(sendForm, 10);
   return false;
}

require(["dijit/ProgressBar", "dojo/domReady"], function (progressbar) {
   var indicator = new progressbar({
      id: "login-progressbar",
      value: 100,
      indeterminate: true
   }).placeAt("login-indicator", "only");
   indicator.startup();
});
