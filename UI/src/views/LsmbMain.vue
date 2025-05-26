<!-- @format -->

<script>
/* global require */
import { provide, computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import Toaster from "@/components/Toaster";
import {
    ClosePopup,
    LocalStorage,
    QTree,
    QDialog,
    QBtn,
    QCard,
    QCardSection,
    QCardActions,
    QIcon,
    QSplitter
} from "quasar";
import { createToasterMachine } from "@/components/Toaster.machines";

import { useMenuStore } from "@/store/menu";

const dojoParser = require("dojo/parser");

export default {
    name: "LsmbMain",
    components: {
        Toaster,
        QTree,
        QDialog,
        QBtn,
        QCard,
        QCardSection,
        QCardActions,
        QIcon,
        QSplitter
    },
    directives: {
        ClosePopup
    },
    plugins: {
        LocalStorage
    },
    setup() {
        const { t } = useI18n({ useScope: "global" });

        const menuStore = useMenuStore();

        const toasterMachine = createToasterMachine({ items: [] }, {});
        provide("toaster-machine", toasterMachine);

        const { send } = toasterMachine;
        provide("notify", (notification) => {
            send({ type: "add", item: notification });
        });

        const menuLoading = computed(() => menuStore.nodes === null);
        const menuNodes = computed(() => menuStore.toplevelNodes);
        const selectedMenuNode = ref(null);
        return { t, menuStore, menuLoading, menuNodes, selectedMenuNode };
    },
    data() {
        const cfg = window.lsmbConfig;
        return {
            savedSelectedMenuNode: null,
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
        },
        selectedMenuNode(newValue) {
            if (newValue === null) {
                // instead of un-selecting, un- *and* re-select
                // to trigger the menu action with the click on the element
                this.$nextTick(() => {
                    this.selectedMenuNode = this.savedSelectedMenuNode;
                });
                return;
            }
            this.savedSelectedMenuNode = newValue;
            this.onMenuSelectedUpdate(newValue);
        }
    },
    mounted() {
        window.__lsmbLoadLink = (url) => {
            let tgt = url.replace(/^https?:\/\/(?:[^@/]+)/, "");
            if (!tgt.startsWith("/")) {
                tgt = "/" + tgt;
            }
            this.$router.push(tgt);
        };
        let m = document.getElementById("main");
        dojoParser.parse(m).then(() => {
            document.body.setAttribute("data-lsmb-done", "true");
        });
        this.menuStore.initialize();
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
        },
        onMouseDown(evt) {
            this._lastMouseEvent = {
                timestamp: Date.now(),
                button: evt.button,
                modifiers: {
                    altKey: evt.altKey,
                    shiftKey: evt.shiftKey,
                    ctrlKey: evt.ctrlKey,
                    metaKey: evt.metaKey
                }
            };
        },
        onMenuSelectedUpdate(id) {
            if (id === null) {
                return;
            }

            this.savedSelectedMenuNode = id;
            const n = this.menuStore.nodeById(id);
            let url = n.url;
            let button = 0;
            let modifiers = {};
            if (
                this._lastMouseEvent &&
                Date.now() - this._lastMouseEvent.timestamp < 250
            ) {
                modifiers = this._lastMouseEvent.modifiers;
                button = this._lastMouseEvent.button;
            }
            let newWindow =
                (button === 0 /* left */ &&
                    (modifiers.ctrlKey || modifiers.metaKey)) ||
                button === 1 /* middle */ ||
                n.standalone;
            if (newWindow) {
                /* eslint no-restricted-globals: 0 */
                // Simulate a target="_blank" attribute on an A tag
                window.open(
                    location.origin +
                        location.pathname +
                        location.search +
                        (url ? "#" + url : ""),
                    "_blank",
                    "noopener,noreferrer"
                );
            } else {
                // Add timestamp to url so that it is unique.
                // A workaround for the blocking of multiple multiple clicks
                // for the same url (see the MainContentPane.js load_link
                // function).
                url += "#" + Date.now();

                if (window.__lsmbLoadLink) {
                    if (url.charAt(0) !== "/") {
                        url = "/" + url;
                    }
                    window.__lsmbLoadLink(url);
                }
            }
        },
        onMenuLoad({ key, done }) {
            const children = this.menuStore.children(key);
            done(children);
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
                <div
                    id="menudiv"
                    style="box-sizing: border-box; padding: 5px; margin: 15px"
                >
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

                    <p v-if="menuLoading">Menu is loading</p>

                    <q-tree
                        v-else
                        v-model:selected="selectedMenuNode"
                        dense
                        :nodes="menuNodes"
                        node-key="id"
                        @mousedown="onMouseDown"
                        @lazy-load="onMenuLoad"
                    ></q-tree>
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
