<script>
import { provide, ref } from "vue";
import i18n, { setI18nLanguage } from "@/i18n";
import { useI18n } from "vue-i18n";
import Toaster from "@/components/Toaster";
import { createToasterMachine } from "@/components/Toaster.machines";

const dojoParser = require("dojo/parser");

export default {
    name: "Main",
    components: {
        Toaster
    },
    data() {
        return {
            modelValue: 50,
            version: window.lsmbConfig.version,
            login: 'my user',
            company: 'the-company'
        }
    },
    setup() {
        const { t, locale } = useI18n({ scope: 'global' });
        console.log(`setting language ${locale.value}`);
        setI18nLanguage(locale);

        const toasterMachine = createToasterMachine({ items: [] }, {});
        provide( "toaster-machine", toasterMachine );

        const { send } = toasterMachine;
        provide("notify", (notification) => {
            send({ type: "add", item: notification });
        });
        return { t };
    },
    beforeUpdate() {
        document.body.removeAttribute("data-lsmb-done");
    },
    updated() {
        document.body.setAttribute("data-lsmb-done", "true");
    },
    mounted() {
        window.__lsmbLoadLink = (url) =>
            this.$router.push(url.replace(/^https?:\/\/(?:[^@/]+)/, ""));
        let m = document.getElementById("main");
        dojoParser.parse(m).then(() => {
            document.body.setAttribute("data-lsmb-done", "true");
        });
    }
};
</script>

<template>
    <div id="console-container"
         data-dojo-type="dijit/layout/BorderContainer"
         data-dojo-props="persist: true"
         style="width: 100%; height: 100%">
        <div data-dojo-type="dijit/layout/ContentPane"
             data-dojo-props="region:'center'"
             id="maindiv">
            <router-view></router-view>
        </div>
        <div id="menudiv" class="edgePanel"
             style="width:30ex"
             data-dojo-type="dijit/layout/ContentPane"
             data-dojo-props="region: 'left', splitter: true, minSize: 200">
            <div style="text-align: center"><a target="_blank"
                                               rel="noopener noreferrer"
                                               href="http://ledgersmb.org/">
                <img class="cornerlogo"
                     src="images/ledgersmb_small-trans.png"
                     width="100"
                     height="50"
                     style="border:1px"
                     alt="LedgerSMB" />
            </a>
            </div>
            <div id="version_info">{{ $t('LedgerSMB {0}',
                                   [ version ]) }}</div>
            <table id="header_info" class="header_table">
                <tr>
                    <td id="login_info_header" class="header_left">
                        {{ $t("User") }}
                    </td>
                    <td id="company_info_header"
                        class="header_right">
                        {{ $t("Company") }}
                    </td>
                </tr>
                <tr>
                    <td id="login_info" class="header_left">{{ login }}</td>
                    <td id="company_info" class="header_right">{{ company }}</td>
                </tr>
            </table>
            <hr>

            <div id="top_menu" data-dojo-type="lsmb/menus/Tree">
            </div>
        </div>
        <div id="errorDialog" title="An error occurred!"
             style="display:none;min-width:40ex"
             data-dojo-type="dijit/Dialog"></div>
    </div>
    <Toaster />
</template>
