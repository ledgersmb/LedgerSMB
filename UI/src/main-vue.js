/** @format */
/* eslint-disable no-console, import/no-unresolved */

import { createApp } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";

const registry = require("dijit/registry");
const dojoParser = require("dojo/parser");

import Home from "./components/Home";
import ServerUI from "./components/ServerUI";
import ImportCSV from "./components/ImportCSV";

const routes = [
    { name: "home", path: "/", component: Home },
    {
        name: "importCSV",
        path: "/import-csv/:type",
        component: ImportCSV,
        props: true
    },
    {
        name: "default",
        path: "/:pathMatch(.*)",
        component: ServerUI,
        props: (route) => ({ uiURL: route.fullPath }),
        meta: {
            managesDone: true
        }
    }
];

const router = createRouter({
    history: createWebHashHistory(),
    routes
});

const maindiv = document.getElementById("maindiv");

router.beforeEach(() => maindiv.classList.remove("done-parsing"));
router.afterEach((to) => {
    if (!to.meta.managesDone) {
        maindiv.classList.add("done-parsing");
    }
});


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
app.config.compilerOptions.isCustomElement = (tag) => tag.startsWith("lsmb-");

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
