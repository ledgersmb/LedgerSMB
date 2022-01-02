/** @format */

import { createRouter, createWebHashHistory } from "vue-router";

import Home from "./components/Home";
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

export default router;
