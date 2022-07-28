/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

export const useWarehousesStore = defineStore("warehouses", {
    ...configStoreTemplate,
    state: () => {
        return {
            fields: ["id", "description"],
            id: "id",
            items: [],
            _links: [],
            url: "products/warehouses"
        };
    }
});
