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
import messages from "@intlify/unplugin-vue-i18n/messages";

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

export function setI18nLanguage(locale) {
    document.querySelector("html").setAttribute("lang", locale.value);
    if (rtlDetect.isRtlLang(locale.value)) {
        document.querySelector("html").setAttribute("dir", "rtl");
    }
}

export default i18n;
