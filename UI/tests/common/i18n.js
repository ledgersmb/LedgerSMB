/** @format */
/* eslint-disable camelcase */

import rtlDetect from "rtl-detect";
import { createI18n } from "vue-i18n";
import en from "@/locales/en.json";
import fr_CA from "@/locales/fr_CA.json";
import ar_EG from "@/locales/ar_EG.json";

function _mapLocale(locale) {
    const _locale = locale.match(/([a-z]{2})-([a-z]{2})/);
    if (_locale) {
        return _locale[1] + "_" + _locale[2].toUpperCase();
    }
    return locale;
}

const _messages = { en, fr_CA, ar_EG };

export const i18n = createI18n({
    useScope: "global",
    legacy: false,
    fallbackWarn: false,
    missingWarn: false, // warning off
    locale: _mapLocale("en"),
    fallbackLocale: "en",
    messages: _messages
});

export async function setI18nLanguage(lang) {
    const locale = _mapLocale(lang.value);

    // If the language hasn't been loaded yet
    if (
        i18n.global.availableLocales.includes(locale) &&
        document.querySelector("html").setAttribute("lang", locale)
    ) {
        if (rtlDetect.isRtlLang(locale)) {
            document.querySelector("html").setAttribute("dir", "rtl");
        }
        i18n.global.locale.value = locale;
    }
}

export default i18n;
