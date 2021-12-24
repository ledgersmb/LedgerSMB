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

router.beforeEach(() => {
    let maindiv = document.getElementById("maindiv");
    if (maindiv) {
        maindiv.removeAttribute("data-lsmb-done");
    }
});
router.afterEach((to) => {
    let maindiv = document.getElementById("maindiv");
    if (!to.meta.managesDone && maindiv) {
        maindiv.setAttribute("data-lsmb-done", "true");
    }
});

export const app = createApp({
    mounted() {
        let m = document.getElementById("main");

        this.$nextTick(() => {
            dojoParser.parse(m).then(() => {
                let r = registry.byId("top_menu");
                if (r) {
                    // Setup doesn't have top_menu
                    r.load_link = (url) => this.$router.push(url);
                }
                const l = document.getElementById("loading");
                if (l) {
                    l.style.display = "none";
                }
                document.body.setAttribute("data-lsmb-done", "true");
            });
        });
        window.__lsmbLoadLink = (url) => this.$router.push(url);
    },
    beforeUpdate() {
        document.body.removeAttribute("data-lsmb-done");
    },
    updated() {
        document.body.setAttribute("data-lsmb-done", "true");
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
        document.body.setAttribute("data-lsmb-done", "true");
    });
}
