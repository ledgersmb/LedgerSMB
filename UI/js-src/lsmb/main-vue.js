/** @format */

import { createApp } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";

const dojoParser = require("dojo/parser");
const dojoDOM    = require("dojo/dom");

import Home from './Home';
import ServerUI from './ServerUI';

const routes = [
    { name: "home", path: "/", component: Home },
    { name: "default", path: "/:pathMatch(.*)", component: ServerUI }
];

const router = createRouter({
    history: createWebHashHistory(),
    routes
});


export const app = createApp({
    mounted() {
        let m = dojoDOM.byId("main");
        dojoParser.parse(m);
    }
}).use(router)
   .mount('#main');
;
