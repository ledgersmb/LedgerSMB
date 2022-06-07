/** @format */

import { defineStore } from "pinia";

export const useWarehousesStore = defineStore("warehouses", {
    state: () => {
        return {
            fields: [ "id", "description" ],
            warehouses: [
            ]
        };
    },
    actions: {
        async initialize() {
            if (this.warehouses.length === 0) {
                this.warehouses.push({ id: 1, description: "ABC" });
            }
            return Promise.resolve();
        },
        async add(adding) {
            this.warehouses.push({ id: this.warehouses.length*2,
                                   description: adding.description });
        },
        async del(id) {
            let index = this.warehouses.findIndex((w) => w.id === id);
            if (index !== -1) {
                this.warehouses.splice(index, 1);
            }
        },
        getById(id) {
            return this.warehouses.find((w) => w.id === id);
        },
        async save(id, data) {
            let warehouse = this.warehouses.find((w) => w.id === id);
            data["id"] = id; // prevent overwriting 'id'
            this.fields.forEach((f) => warehouse[f] = data[f]);
        }
    }
});
