/** @format */
/* global __SUPPORTED_LOCALES */
/* eslint-disable global-require */

export const SUPPORT_LOCALES = __SUPPORTED_LOCALES;

import { nextTick } from "vue";
import { createI18n } from "vue-i18n";

function _mapLocale(locale) {
    const _locale = locale.match(/([a-z]{2})-([a-z]{2})/);
    if (_locale) {
        return _locale[1] + "_" + _locale[2].toUpperCase();
    }
    return locale;
}

const i18n = createI18n({
    globalInjection: true,
    legacy: false,
    fallbackWarn: false,
    missingWarn: false, // warning off
    locale: _mapLocale(window.lsmbConfig.language),
    fallbackLocale: "en",
    messages: {
        en: require("./locales/en.json")
    }
});

export async function loadLocaleMessages(locale) {
    const _locale = _mapLocale(locale);
    if (SUPPORT_LOCALES.includes(_locale)) {
        // load locale messages
        if (!i18n.global.availableLocales.includes(locale)) {
            // load locale messages with dynamic import
            const messages = await import(
                /* webpackChunkName: "locale-[request]" */ `./locales/${_locale}.json`
            );

            // set locale and locale messages
            i18n.global.setLocaleMessage(locale, messages);
        }
        // Update document
        document.querySelector("html").setAttribute("lang", locale);

        // Switch the whole application to this locale
        if (i18n.mode === "legacy") {
            i18n.global.locale = locale;
        } else {
            i18n.global.locale.value = locale;
        }
    }
    return nextTick();
}

export default i18n;
