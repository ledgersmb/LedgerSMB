/** @format */

import { createRouter, createWebHashHistory } from "vue-router";

import Home from "./components/Home.vue";
import ServerUI from "./components/ServerUI";

export function setupRouter() {
    // setup routes
    const routes = [
        { name: "home", path: "/:locale/", component: Home },
        {
            name: "default",
            path: "/:pathMatch(.*)",
            component: ServerUI,
            props: (route) => ({ uiURL: route.fullPath })
        }
    ];

    // create router instance
    const router = createRouter({
        history: createWebHashHistory(),
        routes
    });

    return router;
}
