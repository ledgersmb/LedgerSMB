/** @format */
/* global __SUPPORTED_LOCALES */
/* eslint-disable global-require */
// See https://vue-i18n.intlify.dev/guide/
// And https://vue-i18n.intlify.dev/guide/advanced/wc.html#make-preparetion-for-web-components-to-host-the-i18n-instance

export const SUPPORT_LOCALES = __SUPPORTED_LOCALES;

import { createI18n } from "vue-i18n";

const i18n = createI18n({
    globalInjection: true,
    legacy: false,
    fallbackWarn: false,
    missingWarn: false, // warning off
    locale: window.lsmbConfig.language,
    fallbackLocale: "en",
    messages: {
        en: require("./locales/en.json")
    }
});

function setI18nLanguage(locale) {
    // Update document
    document.querySelector("html").setAttribute("lang", locale);
    i18n.global.locale = locale;
}

export async function loadLocaleMessages(locale) {
    if (SUPPORT_LOCALES.includes(locale)) {
        // load locale messages
        if (!i18n.global.availableLocales.includes(locale)) {
            // load locale messages with dynamic import
            const messages = await import(
                /* webpackChunkName: "locale-[request]" */ `./locales/${locale}.json`
            );

            // set locale and locale message
            i18n.global.setLocaleMessage(locale, messages);
        }
        setI18nLanguage(locale);
    }
}

export default i18n;
