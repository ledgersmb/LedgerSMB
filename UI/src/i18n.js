/** @format */

import { nextTick } from "vue";
import { createI18n } from "vue-i18n";

// It should be dynamic
export const SUPPORT_LOCALES = [
    "ar_EG",
    "bg",
    "ca",
    "ckb",
    "cs",
    "da",
    "de_CH",
    "de",
    "el",
    "en_CA",
    "en_GB",
    "en",
    "en_NZ",
    "es_AR",
    "es_CO",
    "es_EC",
    "es",
    "es_MX",
    "es_PA",
    "es_PY",
    "es_SV",
    "es_VE",
    "et",
    "fa_IR",
    "fi",
    "fr_BE",
    "fr_CA",
    "fr",
    "hu",
    "id",
    "is",
    "it",
    "lt",
    "lv",
    "ms_MY",
    "nb",
    "nl_BE",
    "nl",
    "pl",
    "pt_BR",
    "pt",
    "ru",
    "sv",
    "tr",
    "uk",
    "zh_CN",
    "zh_TW"
];

export function setI18nLanguage(i18n, locale) {
    if (i18n.mode === "legacy") {
        /* eslint-disable-next-line no-param-reassign */
        i18n.global.locale = locale;
    } else {
        /* eslint-disable-next-line no-param-reassign */
        i18n.global.locale.value = locale;
    }
    /**
     * NOTE:
     * If you need to specify the language setting for headers, such as the `fetch` API, set it here.
     * The following is an example for axios.
     *
     * axios.defaults.headers.common['Accept-Language'] = locale
     */
    document.querySelector("html").setAttribute("lang", locale);
}

export function setupI18n(options = { locale: "en" }) {
    const i18n = createI18n(options);
    setI18nLanguage(i18n, options.locale);
    return i18n;
}

export async function loadLocaleMessages(i18n, locale) {
    // load locale messages with dynamic import
    const messages = await import(
        /* webpackChunkName: "locale-[request]" */ `./locales/${locale}.json`
    );

    // set locale and locale message
    i18n.global.setLocaleMessage(locale, messages.default);

    return nextTick();
}
