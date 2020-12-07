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
        history: {},
        addHistory: function (fn) {
            var h = "__";
            var chars =
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            for (var i = 0; i < 25; i++) {
                h += chars.charAt(Math.floor(Math.random() * chars.length));
            }
            this.history[h] = fn;

            return h;
        },
        startup: function () {
            var self = this;
            this.inherited(arguments);

            var mainDiv = registry.byId("maindiv");
            if (mainDiv != null) {
                if (window.location.hash) {
                    let h = hash();
                    if (h && !h.startsWith("__")) {
                        mainDiv.load_link(h);
                    }
                }
                topic.subscribe("/dojo/hashchange", function (h) {
                    if (h in self.history) {
                        self.history[h]();
                    } else if (!h.startsWith("__")) {
                        mainDiv.load_link(h);
                    }
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
