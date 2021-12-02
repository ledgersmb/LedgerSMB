
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
                        ; // throw an error?!
                    } else {
                        this.content = req.response;
                    }
                });
                req.send(options.data || "");
            }
            catch (e) {
                console.log(e);
            }
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
        let widgets = registry.findWidgets(dojoDOM.byId("maindiv"));
        array.forEach(widgets, w => w.destroyRecursive ? w.destroyRecursive(true) : w.destroy());
    },
    updated() {
        return parser.parse(dojoDOM.byId("maindiv"))
            .then(() => query("a", dojoDOM.byId("maindiv")).forEach(node => this._interceptClick(node)));
    },
    render() {
        return h("div", { innerHTML: this.content });
    }
};
