/** @format */
/* global __SUPPORTED_LOCALES */
/* eslint-disable global-require */
/* eslint-disable camelcase, prettier/prettier */

export const SUPPORT_LOCALES = __SUPPORTED_LOCALES;
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
// import messages from "@intlify/unplugin-vue-i18n/messages";
// The above works in production but put webpack-dev-server in infinite compile loop.
// The patch below is used instead.
import ar_EG from "@/locales/ar_EG.json";
import bg from "@/locales/bg.json";
import ca from "@/locales/ca.json";
import cs from "@/locales/cs.json";
import da from "@/locales/da.json";
import de_CH from "@/locales/de_CH.json";
import de from "@/locales/de.json";
import el from "@/locales/el.json";
import en_CA from "@/locales/en_CA.json";
import en_GB from "@/locales/en_GB.json";
import en from "@/locales/en.json";
import en_NZ from "@/locales/en_NZ.json";
import es_AR from "@/locales/es_AR.json";
import es_CO from "@/locales/es_CO.json";
import es_EC from "@/locales/es_EC.json";
import es from "@/locales/es.json";
import es_MX from "@/locales/es_MX.json";
import es_PA from "@/locales/es_PA.json";
import es_PY from "@/locales/es_PY.json";
import es_SV from "@/locales/es_SV.json";
import es_VE from "@/locales/es_VE.json";
import et from "@/locales/et.json";
import fa_IR from "@/locales/fa_IR.json";
import fi from "@/locales/fi.json";
import fr_BE from "@/locales/fr_BE.json";
import fr_CA from "@/locales/fr_CA.json";
import fr from "@/locales/fr.json";
import hu from "@/locales/hu.json";
import id from "@/locales/id.json";
import is from "@/locales/is.json";
import it from "@/locales/it.json";
import lt from "@/locales/lt.json";
import lv from "@/locales/lv.json";
import ms_MY from "@/locales/ms_MY.json";
import nb from "@/locales/nb.json";
import nl_BE from "@/locales/nl_BE.json";
import nl from "@/locales/nl.json";
import pl from "@/locales/pl.json";
import pt_BR from "@/locales/pt_BR.json";
import pt from "@/locales/pt.json";
import ru from "@/locales/ru.json";
import sv from "@/locales/sv.json";
import tr from "@/locales/tr.json";
import uk from "@/locales/uk.json";
import zh_CN from "@/locales/zh_CN.json";
import zh_TW from "@/locales/zh_TW.json";

const i18n = createI18n({
    globalInjection: true,
    useScope: "global",
    legacy: false,
    fallbackWarn: false,
    missingWarn: false, // warning off
    locale: _mapLocale(window.lsmbConfig.language),
    fallbackLocale: "en",
    messages: {
        ar_EG, bg, ca, cs, da, de_CH, de, el, en_CA, en_GB, en, en_NZ,
        es_AR, es_CO, es_EC, es, es_MX, es_PA, es_PY, es_SV, es_VE, et,
        fa_IR, fi, fr_BE, fr_CA, fr, hu, id, is, it, lt, lv, ms_MY, nb,
        nl_BE, nl, pl, pt_BR, pt, ru, sv, tr, uk, zh_CN, zh_TW
    }
});

export function setI18nLanguage(locale) {
    document.querySelector("html").setAttribute("lang", locale.value);
    if (rtlDetect.isRtlLang(locale.value)) {
        document.querySelector("html").setAttribute("dir", "rtl");
    }
}

export default i18n;
