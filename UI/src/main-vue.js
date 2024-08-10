/** @format */

import { createApp } from "vue";
import router from "@/router";
import { useI18n } from "vue-i18n";
import i18n from "@/i18n";
import LoginPage from "@/views/LoginPage";
import Main from "@/views/Main";

import { useSessionUserStore } from "@/store/sessionUser";

import { createPinia } from "pinia";

const dojoParser = require("dojo/parser");

let app, appName;
let lsmbDirective = {
    beforeMount(el, binding /* , vnode */) {
        let handler = (event) => {
            binding.instance[binding.arg] = event.target.value;
        };
        el.addEventListener("input", handler);
        el.addEventListener("change", handler);
    }
};

if (document.getElementById("main")) {
    app = createApp(Main)
        .use(router)
        .use(createPinia());

    useSessionUserStore().initialize();
    appName = "#main";
} else if (document.getElementById("login")) {
    app = createApp(LoginPage);
    appName = "#login";
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
if (app) {
    app.config.compilerOptions.isCustomElement = (tag) =>
        tag.startsWith("lsmb-");
    app.directive("update", lsmbDirective);
    app.use(i18n);
    app.mount(appName);
}
