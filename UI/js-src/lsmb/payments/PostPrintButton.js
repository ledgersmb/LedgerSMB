/** @format */

define([
    "dojo/_base/declare",
    "dojo/_base/event",
    "dijit/form/Button",
    "dojo/request/xhr",
    "dojo/dom-form",
    "dojo/dom-attr",
    "dijit/registry"
], function (declare, event, button, xhr, domform, domattr, registry) {
    return declare("lsmb/payments/PostPrintButton", [button], {
        onClick: function (evt) {
            var f = this.valueNode.form;
            event.stop(evt);

            var data = domform.toObject(f);
            data.action = this.get("value");

            xhr(domattr.get(f, "action"), {
                method: "POST",
                data: data,
                handleAs: "blob"
            }).then(
                function (blob) {
                    // Create a link pointing to the ObjectURL
                    // containing the blob.
                    const _data = window.URL.createObjectURL(blob);
                    var link = document.createElement("a");
                    link.href = _data;
                    link.download = "print-payment.html";
                    link.click();
                    setTimeout(function () {
                        // For some Firefox versions it is necessary to delay
                        // revoking the ObjectURL
                        window.URL.revokeObjectURL(_data);
                    }, 100);
                    registry
                        .byId("maindiv")
                        .load_link(
                            "payment.pl?action=payment&account_class=" +
                                _data.account_class +
                                "&type=" +
                                _data.type
                        );
                },
                function (err) {
                    registry.byId("maindiv").report_request_error(err);
                }
            );
        }
    });
});
