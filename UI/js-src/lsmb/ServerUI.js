
import { h, createComponent } from "vue";
//import axios from "axios";

const registry = require("dijit/registry");
const parser   = require("dojo/parser");
const dojoDOM  = require("dojo/dom");
const array    = require("dojo/_base/array");

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
        }
    },
    beforeRouteEnter() {
    },
    beforeRouteUpdate() {
        let widgets = registry.findWidgets(dojoDOM.byId("maindiv"));
        array.forEach(widgets, w => w.destroyRecursive ? w.destroyRecursive() : w.destroy());
    },
    beforeRouteLeave() {
    },
    mounted() {
        this.$nextTick(() => this.updateContent(this.uiURL));
    },
    updated() {
        parser.parse(dojoDOM.byId("maindiv"));
    },
    render(createElement) {
        return h('div', { innerHTML: this.content });
    }
};
