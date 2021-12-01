/** @format */
/* eslint-disable no-console */

import { createApp } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";

const registry   = require("dijit/registry");
const dojoParser = require("dojo/parser");
const dojoDOM = require("dojo/dom");

import Home from "./Home.vue";
import ServerUI from "./ServerUI";

const routes = [
    { name: "home", path: "/", component: Home },
    { name: "default", path: "/:pathMatch(.*)", component: ServerUI,
      props: route => ({ uiURL: route.fullPath }) }
];

const router = createRouter({
    history: createWebHashHistory(),
    routes
});


export const app = createApp({
    components: [
        Home, ServerUI
    ],
    mounted() {
        let m = dojoDOM.byId("main");
        dojoParser.parse(m);
        let r = registry.byId("top_menu");
        if ( r ) { // Setup doesn't have top_menu
            r.load_link =
                url => this.$router.push(url);
        }
    }
})
    .use(router)
    .mount("#main");
