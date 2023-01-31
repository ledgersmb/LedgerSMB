/** @format */

/* eslint-disable-next-line import/no-unresolved */
import { createRouter, createWebHashHistory } from "vue-router";

import Home from "@/views/Home";
import ServerUI from "@/components/ServerUI";
import ImportCsvAaBatch from "@/views/ImportCSV-AA-Batch";
import ImportCsvCoA from "@/views/ImportCSV-CoA";
import ImportCsvGl from "@/views/ImportCSV-GL";
import ImportCsvGlBatch from "@/views/ImportCSV-GL-Batch";
import ImportCsvGSO from "@/views/ImportCSV-GSO";
import ImportCsvInventory from "@/views/ImportCSV-Inventory";
import ImportCsvTimecard from "@/views/ImportCSV-Timecard";
import Warehouses from "@/views/Warehouses.vue";
import Pricegroups from "@/views/Pricegroups.vue";
import Languages from "@/views/Languages.vue";
import SIC from "@/views/SIC.vue";
import BusinessTypes from "@/views/BusinessTypes.vue";
import GIFI from "@/views/GIFI.vue";

const routes = [
    { name: "home", path: "/", component: Home },
    { name: "warehouses", path: "/warehouses", component: Warehouses },
    { name: "pricegroups", path: "/pricegroups", component: Pricegroups },
    { name: "languages", path: "/languages", component: Languages },
    { name: "sics", path: "/sics", component: SIC },
    { name: "gifis", path: "/gifis", component: GIFI },
    {
        name: "business-types",
        path: "/business-types",
        component: BusinessTypes
    },
    {
        name: "importCSV-AR-Batch",
        path: "/import-csv/ar_multi",
        component: ImportCsvAaBatch,
        props: { type: "ar_multi", multi: true }
    },
    {
        name: "importCSV-AP-Batch",
        path: "/import-csv/ap_multi",
        component: ImportCsvAaBatch,
        props: { type: "ap_multi", multi: true }
    },
    {
        name: "importCSV-CoA",
        path: "/import-csv/chart",
        component: ImportCsvCoA
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
