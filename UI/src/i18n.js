/** @format */
/* global __SUPPORTED_LOCALES */
/* eslint-disable global-require */

export const SUPPORT_LOCALES = __SUPPORTED_LOCALES;
const rtlDetect = require("rtl-detect");

import { nextTick } from "vue";
import { createI18n } from "vue-i18n";

function _mapLocale(locale) {
    const _locale = locale.match(/([a-z]{2})-([a-z]{2})/);
    if (_locale) {
        return _locale[1] + "_" + _locale[2].toUpperCase();
    }
    return locale;
}

var _messages = {};
SUPPORT_LOCALES.forEach(function (it) {
    _messages[it] = require("./locales/" + it + ".json");
});

const i18n = createI18n({
    globalInjection: true,
    useScope: "global",
    legacy: false,
    fallbackWarn: false,
    missingWarn: false, // warning off
    locale: _mapLocale(window.lsmbConfig.language),
    fallbackLocale: "en",
    messages: _messages
});

export function setI18nLanguage(locale) {
    if (i18n.mode === "legacy") {
        i18n.global.locale = locale;
    } else {
        i18n.global.locale.value = locale;
    }
    document.querySelector("html").setAttribute("lang", locale);
    if (rtlDetect.isRtlLang(locale)) {
        document.querySelector("html").setAttribute("dir", "rtl");
    }
}

export async function loadLocaleMessages(locale) {
    let _locale = _mapLocale(locale);
    if (SUPPORT_LOCALES.includes(_locale)) {
        // load locale messages
        if (!i18n.global.availableLocales.includes(_locale)) {
            // load locale messages with dynamic import
            const messages = await import(
                /* webpackChunkName: "locale-[request]" */ `./locales/${_locale}.json`
            );
            // set locale and locale messages
            i18n.global.setLocaleMessage(_locale, messages);
        }
    } else {
        _locale = "en";
    }
    setI18nLanguage(_locale);
    return nextTick();
}

loadLocaleMessages(window.lsmbConfig.language);

export default i18n;
