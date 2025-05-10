<!-- @format -->

<script>
/* global require */
import { provide } from "vue";
import { useI18n } from "vue-i18n";
import Toaster from "@/components/Toaster";
import { createToasterMachine } from "@/components/Toaster.machines";

const dojoParser = require("dojo/parser");

export default {
    name: "LsmbMain",
    components: {
        Toaster
    },
    setup() {
        const { t } = useI18n({ useScope: "global" });

        const toasterMachine = createToasterMachine({ items: [] }, {});
        provide("toaster-machine", toasterMachine);

        const { send } = toasterMachine;
        provide("notify", (notification) => {
            send({ type: "add", item: notification });
        });
        return { t };
    },
    data() {
        const cfg = window.lsmbConfig;
        return {
            splitterPosition: this.getSavedPosition(),
            company: cfg.company,
            login: cfg.login,
            pwExpiration: window.pw_expiration,
            showPasswordAlert: window.pw_expiration !== null,
            version: cfg.version
        };
    },
    watch: {
        splitterPosition(newValue) {
            try {
                localStorage.setItem("splitterPosition", newValue);
            } catch {
                // ignore errors
            }
        }
    },
    mounted() {
        window.__lsmbLoadLink = (url) =>
            this.$router.push(url.replace(/^https?:\/\/(?:[^@/]+)/, ""));
        let m = document.getElementById("main");
        dojoParser.parse(m).then(() => {
            document.body.setAttribute("data-lsmb-done", "true");
        });
    },
    beforeUpdate() {
        document.body.removeAttribute("data-lsmb-done");
    },
    updated() {
        document.body.setAttribute("data-lsmb-done", "true");
    },
    methods: {
        getSavedPosition() {
            const saved = localStorage.getItem("splitterPosition");
            return saved ? parseFloat(saved) : 350;
        }
    }
};
</script>

<template>
    <div style="height: 100%; box-sizing: border-box">
        <q-splitter
            v-model="splitterPosition"
            unit="px"
            style="height: 100%; box-sizing: border-box"
        >
            <template #after>
                <div id="maindiv" style="margin: 15px">
                    <router-view />
                </div>
            </template>
            <template #before>
                <div style="box-sizing: border-box; padding: 5px; margin: 15px">
                    <div style="text-align: center">
                        <a
                            target="_blank"
                            rel="noopener noreferrer"
                            href="http://ledgersmb.org/"
                        >
                            <img
                                class="cornerlogo"
                                src="images/ledgersmb_small-trans.png"
                                width="100"
                                height="50"
                                style="border: 1px"
                                alt="LedgerSMB"
                            />
                        </a>
                    </div>
                    <div id="version_info">
                        {{ t("LedgerSMB {version}", { version: version }) }}
                    </div>
                    <table id="header_info" class="header_table">
                        <tbody>
                            <tr>
                                <td id="login_info_header" class="header_left">
                                    {{ t("User") }}
                                </td>
                                <td
                                    id="company_info_header"
                                    class="header_right"
                                >
                                    {{ t("Company") }}
                                </td>
                            </tr>
                            <tr>
                                <td id="login_info" class="header_left">
                                    {{ login }}
                                </td>
                                <td id="company_info" class="header_right">
                                    {{ company }}
                                </td>
                            </tr>
                        </tbody>
                    </table>
                    <hr />

                    <div id="top_menu" data-dojo-type="lsmb/menus/Tree" />
                </div>
            </template>
        </q-splitter>

        <q-dialog v-model="showPasswordAlert">
            <q-card>
                <q-card-section>
                    <div class="text-h6">
                        <q-icon name="mdi-alert-outline"></q-icon>Alert
                    </div>
                </q-card-section>

                <q-card-section v-if="pwExpiration.years" class="q-pt-none">
                    Your password will expire in
                    {{ pwExpiration.years }} years.
                </q-card-section>
                <q-card-section
                    v-else-if="pwExpiration.months"
                    class="q-pt-none"
                >
                    Your password will expire in
                    {{ pwExpiration.months }} months.
                </q-card-section>
                <q-card-section
                    v-else-if="pwExpiration.weeks"
                    class="q-pt-none"
                >
                    Your password will expire in
                    {{ pwExpiration.weeks }} weeks.
                </q-card-section>
                <q-card-section v-else-if="pwExpiration.days" class="q-pt-none">
                    Your password will expire in
                    {{ pwExpiration.days }} days!
                </q-card-section>
                <q-card-section v-else class="q-pt-none">
                    Your password will expire today!
                </q-card-section>

                <q-card-actions align="right">
                    <q-btn
                        v-close-popup
                        flat
                        label="OK"
                        color="primary"
                    ></q-btn>
                </q-card-actions>
            </q-card>
        </q-dialog>
        <div
            id="errorDialog"
            title="An error occurred!"
            style="display: none; min-width: 40ex"
            data-dojo-type="dijit/Dialog"
        />
    </div>
    <Toaster />
</template>
