/** @format */
/* eslint-disable no-console */

import { createApp } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";

const registry = require("dijit/registry");
const dojoParser = require("dojo/parser");
const dojoDOM = require("dojo/dom");
const domClass = require("dojo/dom-class");

import Home from "./Home.vue";
import ServerUI from "./ServerUI";

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
        let m = dojoDOM.byId("main");
        this.$nextTick(
            () => {
                dojoParser.parse(m);
                domClass.add(document.body, "done-parsing");
            });
        window.__lsmbLoadLink =
            url => this.$router.push(url);

        let r = registry.byId("top_menu");
        if (r) {
            // Setup doesn't have top_menu
            r.load_link = (url) => this.$router.push(url);
        }
    },
    beforeUpdate() {
        domClass.remove(document.body, "done-parsing");
    },
    updated() {
        domClass.add(document.body, "done-parsing");
    }
})
    .use(router);

if (dojoDOM.byId("main")) {
    app.mount("#main");
}
