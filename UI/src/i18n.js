/** @format */
/* eslint-disable no-unused-vars */
const rtlDetect = require("rtl-detect");

import { createI18n } from "vue-i18n";

function _mapLocale(locale) {
    const _locale = locale.match(/([a-z]{2})-([a-z]{2})/);
    if (_locale) {
        return _locale[1] + "_" + _locale[2].toUpperCase();
    }
    return locale;
}

import messages from "@/locales/en.json";
import { nextTick } from "vue";

const i18n = createI18n({
    globalInjection: true,
    useScope: "global",
    legacy: false,
    fallbackWarn: false,
    missingWarn: false, // warning off
    locale: _mapLocale(window.lsmbConfig.language),
    fallbackLocale: "en",
    messages
});

export async function setI18nLanguage(lang) {
    let locale = _mapLocale(lang.value);

    // If the language hasn't been loaded yet
    if (!i18n.global.availableLocales.includes(locale)) {
        try {
            const _messages = await import(
                /* webpackChunkName: "lang-[request]" */ `@/locales/${locale}.json`
            );
            i18n.global.setLocaleMessage(locale, _messages.default);
        } catch (e) {
            const strippedLocale = locale.replace(/_[a-z]+/i, "");
            try {
                const _messages = await import(
                    /* webpackChunkName: "lang-[request]" */ `@/locales/${strippedLocale}.json`
                );
                i18n.global.setLocaleMessage(strippedLocale, _messages.default);
                locale = strippedLocale;
            } catch (f) {
                locale = "en";
            }
        }
    }
    if (i18n.global.locale.value !== locale) {
        i18n.global.locale.value = locale;
    }
    document.querySelector("html").setAttribute("lang", locale);
    if (rtlDetect.isRtlLang(locale)) {
        document.querySelector("html").setAttribute("dir", "rtl");
    } else {
        document.querySelector("html").removeAttribute("dir");
    }
    return nextTick();
}

await setI18nLanguage({ value: window.lsmbConfig.language });

export default i18n;
