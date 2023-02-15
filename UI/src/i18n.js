/** @format */
/* eslint-disable global-require */
/* eslint-disable camelcase, prettier/prettier */

const rtlDetect = require("rtl-detect");

import { createI18n } from "vue-i18n";

function _mapLocale(locale) {
    const _locale = locale.match(/([a-z]{2})-([a-z]{2})/);
    if (_locale) {
        return _locale[1] + "_" + _locale[2].toUpperCase();
    }
    return locale;
}

// eslint-disable-next-line import/no-unresolved
import messages from '@/locales/en.json'
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
    const locale = _mapLocale(lang.value);

    // If the language hasn't been loaded yet
    if (!i18n.global.availableLocales.includes(locale)) {  
        const _messages = await import(/* webpackChunkName: "lang-[request]" */ `@/locales/${locale}.json`);
        i18n.global.setLocaleMessage(locale, _messages.default);
    }
    if ( !i18n.global.locale.value === locale ){
        document.querySelector("html").setAttribute("lang", locale);
        if (rtlDetect.isRtlLang(locale)) {
            document.querySelector("html").setAttribute("dir", "rtl");
        }
        i18n.global.locale.value = locale;
    }
    return nextTick();
}

await setI18nLanguage({value: window.lsmbConfig.language});

export default i18n;
