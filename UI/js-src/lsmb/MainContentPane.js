/** @format */
/* eslint no-param-reassign:0, guard-for-in:0 */

define([
    "dijit/layout/ContentPane",
    "dojo/_base/declare",
    "dojo/_base/event",
    "dojo/_base/lang",
    "dijit/registry",
    "dojo/dom-style",
    "dojo/on",
    "dojo/promise/Promise",
    "dojo/Deferred",
    "dojo/promise/all",
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
    Deferred,
    all,
    query,
    mouse,
    domClass,
    topic
) {
    var docURL = new URL(document.location);
    var domReject = function (request) {
        return (
            request.getResponseHeader("X-LedgerSMB-App-Content") !== "yes" ||
            (request.getResponseHeader("Content-Disposition") || "").startsWith(
                "attachment"
            )
        );
    };
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

            var href = dnode.href;
            on(dnode, "click", function (e) {
                if (!e.ctrlKey && !e.shiftKey && mouse.isLeft(e)) {
                    event.stop(e);
                    self.load_link(href);
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
            var body = doc.match(/<body[^>]*>([\s\S]*)(<\/body>)?/i);

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
            var tgt = new URL(url, docURL);
            if (tgt.origin !== docURL.origin) {
                return new Deferred().resolve();
            }

            var self = this;
            self.fade_main_div();
            var req = new XMLHttpRequest();
            var dfd = new Deferred(function () {
                req.abort();
            });
            try {
                req.open(options.method || "GET", tgt);
                var headers = options.headers || {};
                for (var hdr in headers) {
                    req.setRequestHeader(hdr, headers[hdr]);
                }
                req.setRequestHeader("X-Requested-With", "XMLHttpRequest");
                if (
                    options.data &&
                    !(options.data instanceof FormData) &&
                    !headers["Content-Type"]
                ) {
                    req.setRequestHeader(
                        "Content-Type",
                        "application/x-www-form-urlencoded"
                    );
                }
                req.addEventListener("load", function () {
                    if (req.status >= 400) {
                        dfd.reject(req);
                    } else {
                        dfd.resolve(req);
                    }
                });
                req.addEventListener("error", function () {
                    dfd.reject(req);
                });
                req.send(options.data || "");
            } catch (e) {
                dfd.reject(e);
            }
            return dfd.then(
                function (request) {
                    if (domReject(request)) {
                        self.report_error("Server returned insecure response");
                        return self.show_main_div();
                    }

                    self.hide_main_div();
                    return self.set_main_div(request.response);
                },
                function (errOrReq) {
                    let errstr;
                    if (errOrReq instanceof Error) {
                        errstr = "JavaScript error: " + errOrReq.toString();
                    } else if (errOrReq instanceof XMLHttpRequest) {
                        if (errOrReq.status === 0) {
                            errstr = "Could not connect to server";
                        } else if (domReject(errOrReq)) {
                            errstr = "Server returned insecure response";
                        } else {
                            errstr = errOrReq.response;
                        }
                    } else {
                        errstr = "Unknown (JavaScript) error";
                    }

                    self.show_main_div();
                    return self.report_error(errstr);
                }
            );
        },
        load_form: function (url, options) {
            registry.byId("main").navigateTo(url, options);
        },
        download_link: function (/* href */) {},
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
