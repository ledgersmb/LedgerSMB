/** @format */

import { promisify } from "./promisify";
import { createApp } from "vue";
import router from "@/router";
import { createI18n } from "vue-i18n";
import { createPinia } from "pinia";
import LoginPage from "@/views/LoginPage";
import LsmbMain from "@/views/LsmbMain";
import { useSessionUserStore } from "@/store/sessionUser";

import { installQuasar } from "./quasar-init";

const dojoParser = require("dojo/parser");

let locale;
// the 'en' locale is currently empty, but included so any inline
// strings may contain more than just the showable text (e.g. a
// translation context)
let fbLocales = ["en"];
const parts = window.lsmbConfig.language.match(/([a-z]{2})-([a-z]{2})/i);
if (parts) {
    locale = parts[1].toLowerCase() + "_" + parts[2].toUpperCase();
    fbLocales.unshift(parts[1].toLowerCase());
} else {
    locale = window.lsmbConfig.language;
}
let messages = {};
for (let l of [locale, ...fbLocales]) {
    try {
        messages[l] = await import(
            /* webpackChunkName: "lang-[request]" */ `@/locales/${l}.json`
        );
    } catch {
        // do nothing, the file doesn't need to exist
    }
}
const i18n = createI18n({
    globalInjection: true,
    useScope: "global",
    legacy: false,
    missingWarn: false, // warning off
    locale: locale,
    fallbackLocale: fbLocales,
    fallbackFormat: true,
    fallbackWarn: false,
    messages: messages
});

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
    app = createApp(LsmbMain).use(router).use(createPinia());
    installQuasar(app);

    useSessionUserStore().initialize();
    appName = "#main";
} else if (document.getElementById("login")) {
    app = createApp(LoginPage, {
        successFn: (data) => {
            setTimeout(() => {
                window.location.assign(data.target);
            }, 200);
        }
    });
    appName = "#login";
} else {
    /* In case we're running a "setup.pl" page */
    await promisify(dojoParser.parse(document.body));
    const l = document.getElementById("loading");
    if (l) {
        l.style.display = "none";
    }
    document.body.setAttribute("data-lsmb-done", "true");
}
if (app) {
    app.config.compilerOptions.isCustomElement = (tag) =>
        tag.startsWith("lsmb-");
    app.directive("update", lsmbDirective);
    app.use(i18n);
    app.mount(appName);
}
