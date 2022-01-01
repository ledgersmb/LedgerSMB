/** @format */
/* eslint-disable no-console, import/no-unresolved */

import { createApp } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";

const registry = require("dijit/registry");
const dojoParser = require("dojo/parser");

import Home from "./components/Home";
import LoginPage from "./components/LoginPage";
import ServerUI from "./components/ServerUI";
import ImportCsvAaBatch from "./components/ImportCSV-AA-Batch";
import ImportCsvCoA from "./components/ImportCSV-CoA";
import ImportCsvGifi from "./components/ImportCSV-GIFI";
import ImportCsvGl from "./components/ImportCSV-GL";
import ImportCsvGlBatch from "./components/ImportCSV-GL-Batch";
import ImportCsvGSO from "./components/ImportCSV-GSO";
import ImportCsvInventory from "./components/ImportCSV-Inventory";
import ImportCsvSic from "./components/ImportCSV-SIC";
import ImportCsvTimecard from "./components/ImportCSV-Timecard";

const routes = [
    { name: "home", path: "/", component: Home },
    {
        name: "importCSV-AR-Batch",
        path: "/import-csv/ar_multi",
        component: ImportCsvAaBatch,
        props: { type: "ar", multi: true }
    },
    {
        name: "importCSV-AP-Batch",
        path: "/import-csv/ap_multi",
        component: ImportCsvAaBatch,
        props: { type: "ap", multi: true }
    },
    {
        name: "importCSV-CoA",
        path: "/import-csv/chart",
        component: ImportCsvCoA
    },
    {
        name: "importCSV-GIFI",
        path: "/import-csv/gifi",
        component: ImportCsvGifi
    },
    {
        name: "importCSV-GL",
        path: "/import-csv/gl",
        component: ImportCsvGl
    },
    {
        name: "importCSV-GL-Batch",
        path: "/import-csv/gl_multi",
        component: ImportCsvGlBatch
    },
    {
        name: "importCSV-Inventory",
        path: "/import-csv/inventory",
        component: ImportCsvInventory
    },
    {
        name: "importCSV-Inventory-Batch",
        path: "/import-csv/inventory/multi",
        component: ImportCsvInventory,
        props: { multi: true }
    },
    {
        name: "importCSV-Overhead",
        path: "/import-csv/overhead",
        component: ImportCsvGSO,
        props: { type: "overhead" }
    },
    {
        name: "importCSV-Parts",
        path: "/import-csv/parts",
        component: ImportCsvGSO,
        props: { type: "goods" }
    },
    {
        name: "importCSV-Services",
        path: "/import-csv/services",
        component: ImportCsvGSO,
        props: { type: "services" }
    },
    {
        name: "importCSV-SIC",
        path: "/import-csv/sic",
        component: ImportCsvSic
    },
    {
        name: "importCSV-Timecard",
        path: "/import-csv/timecard",
        component: ImportCsvTimecard
    },
    {
        name: "default",
        path: "/:pathMatch(.*)",
        component: ServerUI,
        props: (route) => ({ uiURL: route.fullPath }),
        meta: {
            managesDone: true
        }
    }
];

const router = createRouter({
    history: createWebHashHistory(),
    routes
});

router.beforeEach(() => {
    let maindiv = document.getElementById("maindiv");
    if (maindiv) {
        maindiv.removeAttribute("data-lsmb-done");
    }
});
router.afterEach((to) => {
    let maindiv = document.getElementById("maindiv");
    if (!to.meta.managesDone && maindiv) {
        maindiv.setAttribute("data-lsmb-done", "true");
    }
});

let app;
let lsmbDirective = {
    beforeMount(el, binding /* , vnode */) {
        let handler = (event) => {
            /* eslint-disable no-param-reassign */
            binding.instance[binding.arg] = event.target.value;
        };
        el.addEventListener("input", handler);
        el.addEventListener("change", handler);
    }
};

if (document.getElementById("main")) {
    app = createApp({
        mounted() {
            let m = document.getElementById("main");

            this.$nextTick(() => {
                dojoParser.parse(m).then(() => {
                    let r = registry.byId("top_menu");
                    if (r) {
                        // Setup doesn't have top_menu
                        r.load_link = (url) => this.$router.push(url);
                    }
                    document.body.setAttribute("data-lsmb-done", "true");
                });
            });
            window.__lsmbLoadLink = (url) => this.$router.push(url);
        },
        beforeUpdate() {
            document.body.removeAttribute("data-lsmb-done");
        },
        updated() {
            document.body.setAttribute("data-lsmb-done", "true");
        }
    }).use(router);
    app.config.compilerOptions.isCustomElement = (tag) =>
        tag.startsWith("lsmb-");
    app.directive("update", lsmbDirective);

    app.mount("#main");
} else if (document.getElementById("login")) {
    app = createApp(LoginPage);
    app.config.compilerOptions.isCustomElement = (tag) =>
        tag.startsWith("lsmb-");
    app.directive("update", lsmbDirective);

    app.mount("#login");
} else {
    /* In case we're running a "setup.pl" page */
    dojoParser.parse(document.body).then(() => {
        const l = document.getElementById("loading");
        if (l) {
            l.style.display = "none";
        }
        document.body.setAttribute("data-lsmb-done", "true");
    });
}
