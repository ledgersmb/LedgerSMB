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

                if (this.minimalGET) {
                    data = {
                        action: this.get("value"),
                        type: f.type.value,
                        id: f.id.value,
                        formname: f.formname.value,
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

                var client = new XMLHttpRequest();
                client.open("POST", domattr.get(f, "action"));
                client.responseType = "blob";
                client.onreadystatechange = function () {
                    if (client.readyState === XMLHttpRequest.DONE) {
                        var status = client.status;
                        if (status === 0 || (status >= 200 && status < 400)) {
                            var disp = client.getResponseHeader(
                                "Content-Disposition"
                            );
                            var cd = contentDisposition.parse(disp);
                            if (cd.parameters.filename === undefined) {
                                cd.parameters.filename = "unknown";
                            }
                            if (cd.type && cd.type === "attachment") {
                                var a = document.createElement("a");
                                var h = URL.createObjectURL(client.response);

                                a.download = cd.parameters.filename;
                                a.href = h;
                                a.click();

                                a.remove();
                                URL.revokeObjectURL(h);
                            } else {
                                var d = registry.byId("errorDialog");
                                d.set(
                                    "content",
                                    "Server sent unexpected response."
                                );
                                d.show();
                            }
                        } else {
                            var err = {
                                response: {
                                    data: client.response
                                }
                            };
                            registry.byId("maindiv").report_request_error(err);
                        }
                    }
                };
                client.send(dojo.objectToQuery(data));
                event.stop(evt);
                return;
            }

            this.inherited(arguments);
        }
    });
});
