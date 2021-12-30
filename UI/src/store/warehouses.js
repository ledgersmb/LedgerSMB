/** @format */

import { defineStore } from "pinia";

export const useWarehousesStore = defineStore("warehouses", {
    state: () => {
        return {
            warehouses: [
                { id: 1, description: "ABC" }
            ]
        };
    },
    actions: {
        add(description) {
            this.warehouses.push({ id: this.warehouses.length*2,
                                   description: description });
        }
    }
});
