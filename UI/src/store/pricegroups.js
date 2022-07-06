/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

export const usePricegroupsStore = defineStore("pricegroups", {
    ...configStoreTemplate,
    state: () => {
        return {
            fields: ["id", "description"],
            items: [],
            url: "products/pricegroups/"
        };
    }
});
