/** @format */

define([
    "dojo/_base/declare",
    "dojo/_base/event",
    "dijit/form/Button",
    "dojo/dom-form",
    "dojo/dom-attr"
], function (declare, event, button, domform, domattr) {
    return declare("lsmb/payments/PostPrintButton", [button], {
        onClick: async function (evt) {
            var f = this.valueNode.form;
            event.stop(evt);

            let base = window.location.pathname.replace(/[^/]*$/, "");
            let r = await fetch(base + domattr.get(f, "action"), {
                method: "POST",
                body: domform.toQuery(f)
            });

            if (r.ok) {
                let blob = await r.blob();
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
                window.__lsmbLoadLink(
                    "payment.pl?action=payment&account_class=" +
                        _data.account_class +
                        "&type=" +
                        _data.type
                );
            } else {
                window.__lsmbReportError(r);
            }
        }
    });
});
