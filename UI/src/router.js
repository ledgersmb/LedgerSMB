/** @format */

import { createRouter, createWebHashHistory } from "vue-router";

const routes = [
    { name: "home", path: "/", component: () => import("@/views/Home") },
    {
        name: "warehouses",
        path: "/warehouses",
        component: () => import("@/views/Warehouses")
    },
    {
        name: "pricegroups",
        path: "/pricegroups",
        component: () => import("@/views/Pricegroups")
    },
    {
        name: "languages",
        path: "/languages",
        component: () => import("@/views/Languages")
    },
    {
        name: "countries",
        path: "/countries",
        component: () => import("@/views/Countries")
    },
    { name: "sics", path: "/sics", component: () => import("@/views/SIC") },
    { name: "gifis", path: "/gifis", component: () => import("@/views/GIFI") },
    {
        name: "business-types",
        path: "/business-types",
        component: () => import("@/views/BusinessTypes.vue")
    },
    {
        name: "importCSV-AR-Batch",
        path: "/import-csv/ar_multi",
        component: () => import("@/views/ImportCSV-AA-Batch"),
        props: { type: "ar_multi", multi: true }
    },
    {
        name: "importCSV-AP-Batch",
        path: "/import-csv/ap_multi",
        component: () => import("@/views/ImportCSV-AA-Batch"),
        props: { type: "ap_multi", multi: true }
    },
    {
        name: "importCSV-CoA",
        path: "/import-csv/chart",
        component: () => import("@/views/ImportCSV-CoA")
    },
    {
        name: "importCSV-GL",
        path: "/import-csv/gl",
        component: () => import("@/views/ImportCSV-GL")
    },
    {
        name: "importCSV-GL-Batch",
        path: "/import-csv/gl_multi",
        component: () => import("@/views/ImportCSV-GL-Batch")
    },
    {
        name: "importCSV-Inventory",
        path: "/import-csv/inventory",
        component: () => import("@/views/ImportCSV-Inventory")
    },
    {
        name: "importCSV-Inventory-Batch",
        path: "/import-csv/inventory/multi",
        component: () => import("@/views/ImportCSV-Inventory"),
        props: { multi: true }
    },
    {
        name: "importCSV-Overhead",
        path: "/import-csv/overhead",
        component: () => import("@/views/ImportCSV-GSO"),
        props: { type: "overhead" }
    },
    {
        name: "importCSV-Parts",
        path: "/import-csv/parts",
        component: () => import("@/views/ImportCSV-GSO"),
        props: { type: "goods" }
    },
    {
        name: "importCSV-Services",
        path: "/import-csv/services",
        component: () => import("@/views/ImportCSV-GSO"),
        props: { type: "services" }
    },
    {
        name: "importCSV-Timecard",
        path: "/import-csv/timecard",
        component: () => import("@/views/ImportCSV-Timecard")
    },
    {
        name: "partsgroups",
        path: "/partsgroups",
        component: () => import("@/views/PartsGroups")
    },
    {
        name: "default",
        path: "/:pathMatch(.*)",
        component: () => import("@/components/ServerUI"),
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
