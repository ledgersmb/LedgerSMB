/** @format */

define([
    "dojo/_base/declare",
    "dijit/registry",
    "lsmb/Form",
    "dijit/_Container"
], function (declare, registry, Form, _Container) {
    return declare("lsmb/Invoice", [Form, _Container], {
        removeLine: function (widgetid) {
            let el = document.getElementById(widgetid);

            registry.findWidgets(el).forEach((w) => {
                w.destroyRecursive(true);
            });
            el.remove();
            this.domNode.__action.item("update").click();
        } // removeLine
    });
});
