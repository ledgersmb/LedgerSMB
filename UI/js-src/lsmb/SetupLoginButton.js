/** @format */

define([
    "dojo/_base/declare",
    "dojo/_base/event",
    "dojo/request/xhr",
    "dojo/dom",
    "dijit/form/Button"
], function (declare, event, xhr, dom, Button) {
    var authURL = "setup.pl?action=authenticate&company=postgres";

    return declare("lsmb/SetupLoginButton", [Button], {
        action: null,
        onClick: function (evt) {
            var self = this;
            var username = dom.byId("s-user").value;
            var password = dom.byId("s-password").value;
            var company = encodeURIComponent(dom.byId("database").value);

            event.stop(evt);
            xhr(authURL, {
                user: username,
                password: password
            }).then(
                function () {
                    window.location.href =
                        "setup.pl?action=" +
                        self.action +
                        "&database=" +
                        company;
                },
                function (err) {
                    var status = err.response.status;
                    /* eslint no-alert:0 */
                    if (status === 454) {
                        alert("Company does not exist");
                    } else {
                        alert(
                            "Access denied (" +
                                status +
                                "): Bad username/password"
                        );
                    }
                }
            );
        }
    });
});
