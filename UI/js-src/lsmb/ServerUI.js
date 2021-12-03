/** @format */

import { h, createComponent } from "vue";
//import axios from "axios";

const registry = require("dijit/registry");
const parser   = require("dojo/parser");
const dojoDOM  = require("dojo/dom");
const array    = require("dojo/_base/array");
const on       = require("dojo/on");
const mouse    = require("dojo/mouse");
const event    = require("dojo/_base/event");
const query    = require("dojo/query");
const domClass = require("dojo/dom-class");


function domReject(request) {
    return (
        request.getResponseHeader("X-LedgerSMB-App-Content") !== "yes" ||
            (request.getResponseHeader("Content-Disposition") || "").startsWith(
                "attachment"
            )
    );
};


export default {
    data() {
        return {
            content: "Loading..."
        };
    },
    props: [ "uiURL" ],
    watch: {
        uiURL(newURI) {
            this.updateContent(newURI);
        }
    },
    methods: {
        updateContent(tgt, options) {
            let req = new XMLHttpRequest();
            options = options || {};
            try {
                req.open(options.method || "GET", tgt);
                var headers = options.headers || {};
                for (var hdr in headers) {
                    req.setRequestHeader(hdr, headers[hdr]);
                }
                req.setRequestHeader("X-Requested-With", "XMLHttpRequest");
                req.addEventListener("load", () => {
                    if (req.status >= 400) {
                        this._report_error(req);
                    } else {
                        this.content = req.response;
                    }
                });
                let div = dojoDOM.byId("maindiv");
                if (div) { domClass.remove(div,"done-parsing"); }
                req.send(options.data || "");
            }
            catch (e) {
                this._report_error(e);
            }
        },
        _report_error(errOrReq) {
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

            let d = registry.byId("errorDialog");
            d.set("content", errstr);
            d.show();
        },
        _interceptClick(dnode) {
            var self = this;

            if (dnode.target || !dnode.href) {
                return;
            }

            var href = dnode.href;
            on(dnode, "click", function (e) {
                if (!e.ctrlKey && !e.shiftKey && mouse.isLeft(e)) {
                    event.stop(e);
                    window.__lsmbLoadLink(href);
                }
            });
            var l = window.location;
            dnode.href =
                l.origin +
                l.pathname +
                l.search +
                "#" +
                dnode.href.substring(l.origin.length);
        }
    },
    beforeRouteEnter() {
    },
    beforeRouteUpdate() {
    },
    beforeRouteLeave() {
    },
    mounted() {
        let self = this;
        this.$nextTick(() => this.updateContent(this.uiURL));
        window.__lsmbSubmitForm =
            req => self.updateContent(req.url, req.options);
    },
    beforeUpdate() {
        try {
            let widgets = registry.findWidgets(dojoDOM.byId("maindiv"));
            array.forEach(widgets, w => w.destroyRecursive ? w.destroyRecursive(true) : w.destroy());
        }
        catch (e) { }
    },
    updated() {
        if (! dojoDOM.byId("maindiv")) return;
        parser.parse(dojoDOM.byId("maindiv"))
            .then((children) => {
                array.forEach(children, child => { if (child.resize) { child.resize(); }});
                query("a", dojoDOM.byId("maindiv")).forEach(node => this._interceptClick(node));
                domClass.add(dojoDOM.byId("maindiv"), "done-parsing");
            });
    },
    render() {
        let body = this.content.match(/<body[^>]*>([\s\S]*)(<\/body>)?/i);
        return h("div", { id: "maindiv", innerHTML: body ? body[1] : this.content });
    }
};
