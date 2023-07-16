/** @format */
/* global dojo, dijit */

define(["dojo/_base/declare", "dijit/form/Button"], function (declare, button) {
    return declare("lsmb/payments/ToggleIncludeButton", [button], {
        query: null,
        onClick: function () {
            dojo.query(this.query, this.valueNode.form).forEach(
                function (node) {
                    var n = dijit.getEnclosingWidget(node);
                    n.set("checked", !n.get("checked"));
                }
            );
        }
    });
});
