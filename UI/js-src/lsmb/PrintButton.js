/** @format */
/* global dojo */

define([
    "dojo/_base/declare",
    "dojo/_base/event",
    "dojo/dom-attr",
    "dijit/form/Button",
    "dijit/registry",
    "content-disposition",
    "dojo/dom-form"
], function (
    declare,
    event,
    domattr,
    Button,
    registry,
    contentDisposition,
    domform
) {
    return declare("lsmb/PrintButton", [Button], {
        minimalGET: true,
        onClick: function (evt) {
            var f = this.valueNode.form;
            if (f.media.value === "screen") {
                var data;

                event.stop(evt);
                if (this.minimalGET) {
                    data = {
                        __action: this.get("value"),
                        type: f.type.value,
                        id: f.id.value,
                        // eslint-disable-next-line camelcase
                        workflow_id: f.workflow_id ? f.workflow_id.value : "",
                        formname: f.formname.value,
                        // eslint-disable-next-line camelcase
                        language_code: f.language_code.value,
                        media: "screen",
                        format: f.format.value
                    };
                    // Apparently, transactions do not include a
                    // 'vc' field; so, when we have one, add it.
                    // when we don't... don't.
                    if (f.vc) {
                        data.vc = f.vc.value;
                    }
                } else {
                    data = domform.toObject(f);
                    data[this.get("name")] = this.get("value");
                }

                let base = window.location.pathname.replace(/[^/]*$/, "");
                fetch(base + domattr.get(f, "action"), {
                    method: "POST",
                    body: dojo.objectToQuery(data),
                    headers: {
                        "X-Requested-With": "XMLHttpRequest",
                        "Content-Type": "application/x-www-form-urlencoded"
                    }
                }).then((r) => {
                    if (r.ok) {
                        let rh = r.headers;
                        var disp = rh.get("Content-Disposition");
                        var cd = contentDisposition.parse(disp);
                        if (cd.parameters.filename === undefined) {
                            cd.parameters.filename = "unknown";
                        }
                        if (cd.type && cd.type === "attachment") {
                            r.blob().then((c) => {
                                var a = document.createElement("a");
                                var h = URL.createObjectURL(c);

                                a.download = cd.parameters.filename;
                                a.href = h;
                                a.click();

                                a.remove();
                                URL.revokeObjectURL(h);
                            });
                        } else {
                            var d = registry.byId("errorDialog");
                            d.set(
                                "content",
                                "Server sent unexpected response."
                            );
                            d.show();
                        }
                    } else {
                        window.__lsmbReportError(r);
                    }
                });
            } else {
                this.inherited(arguments);
            }
        }
    });
});
