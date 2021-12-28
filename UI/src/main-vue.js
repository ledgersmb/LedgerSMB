/** @format */
/* eslint-disable no-console */

import { createApp } from "vue";
import { setupRouter } from "./router";
import { setupI18n } from "./i18n";

const registry = require("dijit/registry");
const dojoParser = require("dojo/parser");

const i18n = setupI18n({
    globalInjection: true,
    legacy: false,
    locale: window.lsmbConfig.language,
    fallbackLocale: "en",
    messages: {}
});

import Home from "./components/Home.vue";
import ServerUI from "./components/ServerUI";

const router = setupRouter(i18n);

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
})
    .use(router)
    .use(i18n);

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
