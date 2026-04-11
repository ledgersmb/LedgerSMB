/** @format */

import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import rtlDetect from "rtl-detect";
import { createI18n } from "vue-i18n";

const _require = createRequire(import.meta.url);
const _dirname = dirname(fileURLToPath(import.meta.url));

const SUPPORT_LOCALES = ["en", "fr_CA", "ar_EG"];

function _mapLocale(locale) {
    const _locale = locale.match(/([a-z]{2})-([a-z]{2})/);
    if (_locale) {
        return _locale[1] + "_" + _locale[2].toUpperCase();
    }
    return locale;
}

var _messages = {};
SUPPORT_LOCALES.forEach(function (it) {
    const locale = _mapLocale(it);
    _messages[locale] = _require(
        resolve(_dirname, "../../src/locales/", locale + ".json")
    );
});

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
