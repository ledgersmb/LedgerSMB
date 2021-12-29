/** @format */
/* eslint-disable no-console */

import { createApp } from "vue";
import { setupRouter } from './router'

const registry = require("dijit/registry");
const dojoParser = require("dojo/parser");

import Home from "./components/Home.vue";
import ServerUI from "./components/ServerUI";

const router = setupRouter;

export const app = createApp({
    components: [Home, ServerUI],
    mounted() {
        let m = document.getElementById("main");

        this.$nextTick(() => {
            dojoParser.parse(m).then(() => {
                const l = document.getElementById("loading");
                if (l) {
                    l.style.display = "none";
                }
                document.body.classList.add("done-parsing");
                let r = registry.byId("top_menu");
                if (r) {
                    // Setup doesn't have top_menu
                    r.load_link = (url) => this.$router.push(url);
                }
            });
        });
        window.__lsmbLoadLink = (url) => this.$router.push(url);
    },
    beforeUpdate() {
        document.body.classList.remove("done-parsing");
    },
    updated() {
        document.body.classList.add("done-parsing");
    }
}).use(router);

if (document.getElementById("main")) {
    app.mount("#main");
} else {
    /* In case we're running a "setup.pl" page */
    dojoParser.parse(document.body).then(() => {
        const l = document.getElementById("loading");
        if (l) {
            l.style.display = "none";
        }
        document.body.classList.add("done-parsing");
    });
}
