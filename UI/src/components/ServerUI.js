/** @format */


import { h, inject, ref } from "vue";
import { useI18n } from "vue-i18n";

const registry = require("dijit/registry");
const parser = require("dojo/parser");
const query = require("dojo/query");
const topic = require("dojo/topic");

function domReject(response) {
    return (
        response.headers.get("X-LedgerSMB-App-Content") !== "yes" ||
        (response.headers.get("Content-Disposition") || "").startsWith(
            "attachment"
        )
    );
}

export default {
    setup() {
        const { t } = useI18n();
        const notify = inject("notify");
        return {
            notify,
            content: ref(t("Loading..."))
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
            let dismiss;
            try {
                this.notify({
                    title: options.doing || this.$t("Loading..."),
                    type: "info",
                    dismissReceiver: (cb) => {
                        dismiss = cb;
                    }
                });
                let headers = new Headers(options.headers);
                headers.set("X-Requested-With", "XMLHttpRequest");

                document
                    .getElementById("maindiv")
                    .removeAttribute("data-lsmb-done");
                // chop off the leading '/' to use relative paths
                let base = window.location.pathname.replace(/[^/]*$/, "");
                let relTgt = (tgt.substring(0, 1) === '/') ? tgt.substring(1) : tgt;
                let r = await fetch(base + relTgt, {
                    method: options.method,
                    body: options.data,
                    headers: headers
                    // additional parameters to consider:
                    // mode(cors?), credentials, referrerPolicy?
                });

                if (r.ok && !domReject(r)) {
                    let newContent = await r.text();
                    this.notify({
                        title: options.done || this.$t("Loaded")
                    });
                    if (newContent === this.content) {
                        // when there is no difference in returned content,
                        // Vue won't re-render... so don't rerun the parser!
                        return;
                    }
                    this.content = newContent;
                    this.$nextTick(() => {
                        let maindiv = document.getElementById("maindiv");
                        parser.parse(maindiv).then(
                            () => {
                                registry.findWidgets(maindiv).forEach((child) => {
                                    this._recursively_resize(child);
                                });
                                maindiv
                                    .querySelectorAll("a")
                                    .forEach((node) => this._interceptClick(node));
                                if (dismiss) {
                                    dismiss();
                                }
                                topic.publish("lsmb/page-fresh-content");
                                maindiv.setAttribute("data-lsmb-done", "true");
                                this._setFormFocus();
                            },
                            (e) => {
                                this._report_error(e);
                            });
                    });
                } else {
                    this._report_error(r);
                }
            } catch (e) {
                this._report_error(e);
            } finally {
                if (dismiss) {
                    dismiss();
                }
            }
        },
        _setFormFocus() {
            [ ...document.forms ].forEach(
                (form) => {
                    if (form.hasAttribute('data-lsmb-focus')) {
                        let focus = form.getAttribute('data-lsmb-focus');
                        let elm = document.getElementById(focus);
                        if (elm) {
                            elm.select();
                        }
                    }
                });
        },
        _recursively_resize(widget) {
            widget.getChildren().forEach((child) => {
                this._recursively_resize(child);
            });
            if (widget.resize) {
                widget.resize();
            }
        },
        async _report_error(errOrReq) {
            let errstr;
            if (errOrReq instanceof Error) {
                errstr = this.$t("JavaScript error: ") + errOrReq.toString();
            } else if (errOrReq instanceof Response) {
                if (errOrReq.status === 0) {
                    errstr = this.$t("Could not connect to server");
                } else if (domReject(errOrReq)) {
                    errstr = this.$t("Server returned insecure response");
                } else {
                    errstr = await errOrReq.text();
                }
            } else {
                errstr = this.$t("Unknown (JavaScript) error");
            }

            let d = registry.byId("errorDialog");
            d.set("content", errstr);
            d.show();
        },
        _interceptClick(dnode) {
            let href = dnode.getAttribute('href');
            if (dnode.target || !href) {
                return;
            }

            let i = 0;
            dnode.addEventListener("click", function (e) {
                if (!e.ctrlKey && !e.shiftKey && e.button === 0) {
                    e.preventDefault();
                    window.__lsmbLoadLink(href + `#${i++}`);
                }
            });

            let anode = dnode;
            anode.href = '#' + href;
        },
        _cleanWidgets() {
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
        }
    },
    beforeRouteLeave() {
        this._cleanWidgets();
    },
    mounted() {
        document
            .getElementById("maindiv")
            .setAttribute("data-lsmb-done", "true");
        this.$nextTick(() => this.updateContent(this.uiURL));
        window.__lsmbSubmitForm = (req) =>
            this.updateContent(req.url, req.options);
    },
    beforeUpdate() {
        this._cleanWidgets();
    },
    render() {
        let body = this.content.match(/<body[^>]*>([\s\S]*)(<\/body>)?/i);
        return h("div", {
            innerHTML: body ? body[1] : this.content,
            style: "height:100%"
        });
    }
};
