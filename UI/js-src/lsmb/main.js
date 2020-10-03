/** @format */

define([
    "dojo/_base/declare",
    "dijit/_WidgetBase",
    "dijit/_Container",
    // "dojo/parser",
    "dojo/query",
    "dijit/registry",
    "dojo/hash",
    "dojo/topic",
    "dojo/dom-class",
    "dojo/dom-style"
], function (
    declare,
    _WidgetBase,
    _Container,
    // parser,
    query,
    registry,
    hash,
    topic,
    domClass,
    domStyle
) {
    return declare("lsmb/main", [_WidgetBase, _Container], {
        startup: function () {
            this.inherited(arguments);

            var mainDiv = registry.byId("maindiv");
            if (mainDiv != null) {
                if (window.location.hash) {
                    mainDiv.load_link(hash());
                }
                topic.subscribe("/dojo/hashchange", function (_hash) {
                    mainDiv.load_link(_hash);
                });
            }

            query("#loading").forEach(function (node) {
                domStyle.set(node, "display", "none");
            });
            query("#console-container").forEach(function (node) {
                domClass.add(node, "done-parsing");
            });
            query("body").forEach(function (node) {
                domClass.add(node, "done-parsing");
            });
        }
    });
});
