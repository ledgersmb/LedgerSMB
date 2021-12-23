/** @format */

import { h } from "vue";
// import axios from "axios";

const registry = require("dijit/registry");
const parser = require("dojo/parser");
const query = require("dojo/query");

function domReject(response) {
    return (
        response.headers.get("X-LedgerSMB-App-Content") !== "yes" ||
        (response.headers.get("Content-Disposition") || "").startsWith(
            "attachment"
        )
    );
}

export default {
    data() {
        return {
            content: "Loading..."
        };
    },
    props: ["uiURL"],
    watch: {
        uiURL(newURI) {
            this.updateContent(newURI);
        }
    },
    methods: {
        async updateContent(tgt, options = {}) {
            try {
                let headers = new Headers(options.headers);
                headers.set("X-Requested-With", "XMLHttpRequest");

                document
                    .getElementById("maindiv")
                    .classList.remove("done-parsing");
                let r = await fetch(tgt, {
                    method: options.method,
                    body: options.data,
                    headers: headers
                    // additional parameters to consider:
                    // mode(cors?), credentials, referrerPolicy?
                });

                let b = await r.text();
                if (r.ok && !domReject(r)) {
                    this.content = b;
                } else {
                    this._report_error(r);
                }
            } catch (e) {
                this._report_error(e);
            }
        },
        _recursively_resize(widget) {
            widget.getChildren().forEach((child) => {
                this._recursively_resize(child);
            });
            if (widget.resize) {
                widget.resize();
            }
        },
        _report_error(errOrReq) {
            let errstr;
            if (errOrReq instanceof Error) {
                errstr = "JavaScript error: " + errOrReq.toString();
            } else if (errOrReq instanceof Response) {
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
            if (dnode.target || !dnode.href) {
                return;
            }

            var href = dnode.href;
            dnode.addEventListener("click", function (e) {
                if (!e.ctrlKey && !e.shiftKey && e.button === 0) {
                    e.preventDefault();
                    window.__lsmbLoadLink(href);
                }
            });
        }
    },
    beforeRouteEnter() {},
    beforeRouteUpdate() {},
    beforeRouteLeave() {},
    mounted() {
        document.getElementById("maindiv").classList.add("done-parsing");
        this.$nextTick(() => this.updateContent(this.uiURL));
        window.__lsmbSubmitForm = (req) =>
            this.updateContent(req.url, req.options);
    },
    beforeUpdate() {
        try {
            let widgets = registry.findWidgets(
                document.getElementById("maindiv")
            );
            widgets.forEach((w) =>
                w.destroyRecursive ? w.destroyRecursive(true) : w.destroy()
            );
            // when the BODY-bound mouse-over handler finds a node which has a
            // _cssState prop after the widget that node belongs to was unregistered
            // an error is thrown. Make sure the props are gone right after unregistering
            // the widgets. (it may take a bit for the new content to overwrite the old
            // content...)
            query("*", document.getElementById("maindiv")).forEach(
                /* eslint-disable no-param-reassign */
                (n) => delete n._cssState
            );
        } catch (e) {
            this._report_error(e);
        }
    },
    updated() {
        if (!document.getElementById("maindiv")) {
            return;
        }
        this.$nextTick(() => {
            let maindiv = document.getElementById("maindiv");
            parser.parse(maindiv).then(() => {
                registry.findWidgets(maindiv).forEach((child) => {
                    this._recursively_resize(child);
                });
                maindiv.classList.add("done-parsing");
            });
            maindiv
                .querySelectorAll("a")
                .forEach((node) => this._interceptClick(node));
        });
    },
    render() {
        let body = this.content.match(/<body[^>]*>([\s\S]*)(<\/body>)?/i);
        return h("div", {
            innerHTML: body ? body[1] : this.content,
            style: "height:100%"
        });
    }
};
