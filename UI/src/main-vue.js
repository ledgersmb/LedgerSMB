/** @format */
/* eslint-disable no-console */

import { createApp } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";

const registry = require("dijit/registry");
const dojoParser = require("dojo/parser");

import Home from "./components/Home.vue";
import ServerUI from "./components/ServerUI";

const routes = [
    { name: "home", path: "/", component: Home },
    {
        name: "default",
        path: "/:pathMatch(.*)",
        component: ServerUI,
        props: (route) => ({ uiURL: route.fullPath })
    }
];

const router = createRouter({
    history: createWebHashHistory(),
    routes
});

export const app = createApp({
    components: [Home, ServerUI],
    mounted() {
        let m = document.getElementById("main");

        this.$nextTick(() => {
            dojoParser.parse(m).then(() => {
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
}
