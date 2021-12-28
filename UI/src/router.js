/** @format */

import { createRouter, createWebHashHistory } from "vue-router";
import { setI18nLanguage, loadLocaleMessages, SUPPORT_LOCALES } from "./i18n";

import Home from "./components/Home.vue";
import ServerUI from "./components/ServerUI";

export function setupRouter(i18n) {
    // setup routes
    const routes = [
        { name: "home", path: "/", component: Home },
        {
            name: "default",
            path: "/:pathMatch(.*)",
            component: ServerUI,
            props: (route) => ({ uiURL: route.fullPath })
            // redirect: () => `/${locale}`
        }
    ];

    // create router instance
    const router = createRouter({
        history: createWebHashHistory(),
        routes
    });

    // navigation guards
    router.beforeEach(async (to) => {
        const paramsLocale = to.params.locale;

        // use locale if paramsLocale is in SUPPORT_LOCALES
        if (SUPPORT_LOCALES.includes(paramsLocale)) {
            // load locale messages
            if (!i18n.global.availableLocales.includes(paramsLocale)) {
                await loadLocaleMessages(i18n, paramsLocale);
            }

            // set i18n language
            setI18nLanguage(i18n, paramsLocale);
        }
        return to.params.fullPath;
    });

    return router;
}
