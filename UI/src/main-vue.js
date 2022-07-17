/** @format */
/* eslint-disable no-console, import/no-unresolved, vue/multi-word-component-names */

import { createApp } from "vue";
import router from "./router";
import i18n, { loadLocaleMessages } from "./i18n";
import { useI18n } from "vue-i18n";
import LoginPage from "./components/LoginPage";
import Toaster from "./components/Toaster";
import { createToasterMachine } from "./components/Toaster.machines";
import { useSessionUserStore } from "./store/sessionUser";

import { createPinia } from "pinia";

const registry = require("dijit/registry");
const dojoParser = require("dojo/parser");

let app;
let appName;
let lsmbDirective = {
    beforeMount(el, binding /* , vnode */) {
        let handler = (event) => {
            /* eslint-disable no-param-reassign */
            binding.instance[binding.arg] = event.target.value;
        };
        el.addEventListener("input", handler);
        el.addEventListener("change", handler);
    }
};

if (document.getElementById("main")) {
    app = createApp({
        setup() {
            const { t } = useI18n();
            return { t };
        },
        beforeCreate() {
            // Load the user desired language if not default
            loadLocaleMessages(window.lsmbConfig.language);
        },
        mounted() {
            let m = document.getElementById("main");

            this.$nextTick(() => {
                dojoParser.parse(m).then(() => {
                    let r = registry.byId("top_menu");
                    if (r) {
                        // Setup doesn't have top_menu
                        r.load_link = (url) => this.$router.push(url);
                    }
                    document.body.setAttribute("data-lsmb-done", "true");
                });
            });
            window.__lsmbLoadLink = (url) =>
                this.$router.push(
                    // eslint-disable-next-line no-useless-escape
                    url.replace(/^https?:\/\/(?:[^@\/]+)/, "")
                );
        },
        beforeUpdate() {
            document.body.removeAttribute("data-lsmb-done");
        },
        updated() {
            document.body.setAttribute("data-lsmb-done", "true");
        }
    })
        .use(router)
        .use(createPinia());

    useSessionUserStore().initialize();
    app.component("Toaster", Toaster);
    const toasterMachine = createToasterMachine({ items: [] }, {});
    app.provide("toaster-machine", toasterMachine);
    const { send } = toasterMachine;
    app.provide("notify", (notification) => {
        send({ type: "add", item: notification });
    });

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
