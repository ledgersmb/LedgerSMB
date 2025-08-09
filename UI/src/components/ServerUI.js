/** @format */

import { promisify } from "@/promisify";
import { h, inject, ref } from "vue";
import { useI18n } from "vue-i18n";

import { createServerUIMachine } from "./ServerUI.machines.js";

const registry = require("dijit/registry");
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
    name: "ServerUI",
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
        updateContent(tgt, options = {}) {
            this.machine.send({ type: "loadContent", value: { tgt, options } });
        },
        _setFormFocus() {
            [...document.forms].forEach((form) => {
                if (form.hasAttribute("data-lsmb-focus")) {
                    let focus = form.getAttribute("data-lsmb-focus");
                    if (focus) {
                        let elm = document.getElementById(focus);
                        if (elm) {
                            elm.select();
                        }
                    }
                }
            });
        },
        recursivelyResize(widget) {
            widget.getChildren().forEach((child) => {
                this.recursivelyResize(child);
            });
            if (widget.resize) {
                widget.resize();
            }
        },
        async reportError(errOrReq) {
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
            await promisify(d.show());
        },
        _interceptClick(dnode) {
            let href = dnode.getAttribute("href");
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
            anode.href = "#" + href;
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
                    (n) => delete n._cssState
                );
            } catch (e) {
                this.reportError(e);
            }
        }
    },
    beforeRouteLeave() {
        this.machine.send("unloadContent");
        return this.machine.state.value === "unloaded";
    },
    created() {
        let maindiv = document.getElementById("maindiv");
        this.machine = createServerUIMachine(
            {
                notify: this.notify,
                view: this
            },
            ({ machine }) => {
                if (machine.current === "idle") {
                    topic.publish("lsmb/page-fresh-content");
                    maindiv.setAttribute("data-lsmb-done", "true");
                }
            }
        );
    },
    mounted() {
        document
            .getElementById("maindiv")
            .setAttribute("data-lsmb-done", "true");
        this.$nextTick(() => this.updateContent(this.uiURL));
        window.__lsmbSubmitForm = (req) =>
            this.updateContent(req.url, req.options);
        window.__lsmbReportError = (err) => this.reportError(err);
    },
    render() {
        let body = this.content.match(/<body[^>]*>([\s\S]*)(<\/body>)?/i);
        return h("div", {
            innerHTML: body ? body[1] : this.content,
            style: "height:100%"
        });
    }
};
