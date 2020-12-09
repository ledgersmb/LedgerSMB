/** @format */
/* eslint no-param-reassign:0 */

define([
    "dijit/layout/ContentPane",
    "dojo/_base/declare",
    "dojo/_base/event",
    "dojo/_base/lang",
    "dijit/registry",
    "dojo/dom-style",
    "dojo/on",
    "dojo/promise/Promise",
    "dojo/promise/all",
    "dojo/request/xhr",
    "dojo/hash",
    "dojo/query",
    "dojo/mouse",
    "dojo/dom-class",
    "dojo/topic"
], function (
    ContentPane,
    declare,
    event,
    lang,
    registry,
    domStyle,
    on,
    Promise,
    all,
    xhr,
    hash,
    query,
    mouse,
    domClass,
    topic
) {
    var c = 0;

    return declare("lsmb/MainContentPane", [ContentPane], {
        startup: function () {
            this.inherited("startup", arguments);
            domClass.add(this.domNode, "done-parsing");
        },
        interceptClick: function (dnode) {
            var self = this;

            if (dnode.target || !dnode.href) {
                return;
            }

            var href = dnode.href + "#s";
            on(dnode, "click", function (e) {
                if (!e.ctrlKey && !e.shiftKey && mouse.isLeft(e)) {
                    event.stop(e);
                    c++;
                    hash(href + c.toString(16));
                    self.fade_main_div();
                }
            });
            var l = window.location;
            dnode.href =
                l.origin +
                l.pathname +
                l.search +
                "#" +
                dnode.href.substring(l.origin.length);
        },
        report_request_error: function (err) {
            var d = registry.byId("errorDialog");
            if (err.response.status === 0) {
                d.set("content", "Could not connect to server");
            } else {
                var data = err.response.data;
                if (data instanceof Blob) {
                    data.text().then(function (txt) {
                        d.set("content", txt);
                    });
                } else {
                    d.set("content", err.response.data);
                }
            }
            d.show();
        },
        report_error: function (content) {
            var d = registry.byId("errorDialog");
            d.set("content", content);
            d.show();
        },
        set_main_div: function (doc) {
            var self = this;
            var body = doc.match(/<body[^>]*>([\s\S]*)(<\/body>)+?/i);

            if (!body) {
                this.report_error(
                    "Invalid server response: document lacks BODY tag"
                );
                return undefined;
            }
            var newbody = body[1];
            return this.set("content", newbody).then(
                function () {
                    self.show_main_div();
                },
                function () {
                    self.report_error("Server return value invalid");
                }
            );
        },
        _load_form: function (url, options) {
            var self = this;
            self.fade_main_div();
            return xhr(url, options).then(
                function (doc) {
                    self.hide_main_div();
                    self.set_main_div(doc);
                },
                function (err) {
                    self.show_main_div();
                    self.report_request_error(err);
                }
            );
        },
        load_form: function (url, options) {
            var self = this;
            var h = registry.byId("main").addHistory(function () {
                self._load_form(url, options);
            });
            hash(h);
        },
        /* eslint spaced-comment:0 */
        download_link: function (/*href*/) {
            // while it would have been nice for the code below
            // to work, content downloaded into the iframe through
            // dojo/request/iframe breaks all but the first request
            // supposedly because the response never causes the
            // 'onload' event to fire -- as the content isn't really
            // loaded...
            // var self = this;
            // var deferred = iframe.get(href, { });
            // iframe.doc();
            // return deferred .then(
            //     function() {
            //         // we never reach success???
            //     }, function(err) {
            //         self.report_request_error(err);
            //     });
        },
        load_link: function (href) {
            return this.load_form(href, { handlesAs: "text" });
        },
        fade_main_div: function () {
            // mention we're processing the request
            domClass.replace(this.domNode, "parsing", "done-parsing");
            domStyle.set(this.domNode, "opacity", "0.3");
        },
        hide_main_div: function () {
            domStyle.set(this.domNode, "visibility", "hidden");
        },
        show_main_div: function () {
            domStyle.set(this.domNode, "visibility", "visible");
            domStyle.set(this.domNode, "opacity", "1");
            domClass.replace(this.domNode, "done-parsing", "parsing");
            topic.publish("lsmb/page-fresh-content");
        },
        set: function () {
            var newContent = null;
            var contentOnly = 0;
            var contentPromise = null;
            var self = this;

            if (
                arguments.length === 1 &&
                lang.isObject(arguments[0]) &&
                arguments[0].content !== null
            ) {
                newContent = arguments[0].content;
                delete arguments[0].content;
            } else if (arguments.length === 1 && lang.isString(arguments[0])) {
                newContent = arguments[0];
                contentOnly = true;
            } else if (arguments.length === 2 && arguments[0] === "content") {
                newContent = arguments[1];
                contentOnly = true;
            }

            if (newContent !== null) {
                contentPromise = this.inherited("set", arguments, [
                    "content",
                    newContent
                ]).then(function () {
                    query("a", self.domNode).forEach(function (node) {
                        self.interceptClick(node);
                    });
                    self.show_main_div();
                });
            }

            if (contentOnly) {
                return contentPromise;
            }

            var setPromise = this.inherited(arguments);
            if (
                contentPromise !== null &&
                contentPromise instanceof Promise &&
                setPromise !== null &&
                setPromise instanceof Promise
            ) {
                return all([contentPromise, setPromise]);
            }
            if (contentPromise !== null && contentPromise instanceof Promise) {
                return contentPromise;
            }
            return setPromise;
        }
    });
});
