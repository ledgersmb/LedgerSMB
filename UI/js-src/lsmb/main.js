/** @format */

define([
    "dojo/_base/declare",
    "dijit/_WidgetBase",
    "dijit/_Container",
    "dojo/query",
    "dojo/dom-class",
    "dojo/dom-style"
], function (declare, _WidgetBase, _Container, query, domClass, domStyle) {
    return declare("lsmb/main", [_WidgetBase, _Container], {
        history: {},
        startup: function () {
            this.inherited(arguments);

            query("#loading").forEach(function (node) {
                domStyle.set(node, "display", "none");
            });
            query("body").forEach(function (node) {
                domClass.add(node, "done-parsing");
            });
        }
    });
});
