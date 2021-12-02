/** @format */

define([
    "dijit/form/Form",
    "dojo/_base/declare",
    "dojo/_base/event",
    "dojo/on",
    "dojo/dom-attr",
    "dojo/dom-form",
    "dojo/query",
    "dijit/registry"
], function (Form, declare, event, on, domattr, domform, query, registry) {
    var c = 0;
    return declare("lsmb/Form", [Form], {
        clickedAction: null,
        startup: function () {
            var self = this;
            this.inherited(arguments);

            // <button> tags get rewritten to <input type="submit" tags...
            query('input[type="submit"]', this.domNode).forEach(function (b) {
                on(b, "click", function () {
                    self.clickedAction = b;
                });
            });
        },
        onSubmit: function (evt) {
            event.stop(evt);
            this.submit();
        },
        submit: function () {
            if (!this.validate()) {
                return;
            }

            var method =
                typeof this.method === "undefined" ? "GET" : this.method;
            var url = this.action;
            var options = { handleAs: "text" };
            if (method.toLowerCase() === "get") {
                if (!url) {
                    /* eslint no-alert:0 */
                    alert("Form contains no action. Please file a bug");
                    return;
                }
                c++;
                var qobj = domform.toQuery(this.domNode);
                qobj =
                    domattr.get(this.clickedAction, "name") +
                    "=" +
                    domattr.get(this.clickedAction, "value") +
                    "&" +
                    qobj;
                url = url + "?" + qobj + "#" + c.toString(16);
                window.__lsmbLoadLink(url); // add GET forms to the back button history
            } else {
                options.method = method;
                if (this.domNode.enctype === "multipart/form-data") {
                    options.data = new FormData(this.domNode);
                    // FF doesn't add the clicked button
                    options.data.append(
                        domattr.get(this.clickedAction, "name"),
                        domattr.get(this.clickedAction, "value")
                    );
                } else {
                    // old code (Form.pm) wants x-www-urlencoded
                    options.headers = {
                        "Content-Type": "application/x-www-form-urlencoded"
                    };
                    options.data =
                        domattr.get(this.clickedAction, "name") +
                        "=" +
                        domattr.get(this.clickedAction, "value") +
                        "&" +
                        domform.toQuery(this.domNode);
                }
                window.__lsmbSubmitForm({url, options});
            }
        }
    });
});
