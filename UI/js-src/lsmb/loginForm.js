/** @format */

define([
    "dojo/_base/declare",
    "dojo/request/xhr",
    "dojo/dom",
    "dojo/dom-style",
    "dojo/json",
    "dijit/form/Form",
    "dijit/Dialog",
    "dijit/ProgressBar"
], function (declare, xhr, dom, domStyle, json, Form, dialog, progressBar) {
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
                } else if (status === 401) {
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
                domStyle.set(
                    dom.byId("login-indicator"),
                    "visibility",
                    "hidden"
                );
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
        domStyle.set(dom.byId("login-indicator"), "display", "none");
    }

    return declare("lsmb/loginForm", [Form], {
        startup: function () {
            this.inherited(arguments);
            setIndicator();
        },
        onSubmit: function () {
            showIndicator();
            window.setTimeout(showIndicator, 0);
            window.setTimeout(sendForm, 10);
            return false;
        }
    });
});
