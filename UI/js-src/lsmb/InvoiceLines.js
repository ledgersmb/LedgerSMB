/** @format */

define([
    "dojo/_base/declare",
    "dijit/registry",
    "dijit/_WidgetBase",
    "dijit/_Container"
], function (declare, registry, _WidgetBase, _Container) {
    return declare("lsmb/InvoiceLines", [_WidgetBase, _Container], {
        removeLine: function (widgetid) {
            registry.byId(widgetid).destroyRecursive(false);

            this.emit("changed", { action: "removed" });
        } // removeLine
    });
});
