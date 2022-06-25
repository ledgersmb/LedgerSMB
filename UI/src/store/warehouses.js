/** @format */

import { defineStore } from "pinia";

export const useWarehousesStore = defineStore("warehouses", {
    state: () => {
        return {
            fields: ["id", "description"],
            warehouses: []
        };
    },
    actions: {
        async initialize() {
            const response = await fetch("./erp/api/v0/products/warehouses/", {
                method: "GET"
            });

            if (response.ok) {
                this.warehouses = (await response.json()).sort(
                    (a, b) => b.id - a.id
                );
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
            return Promise.resolve();
        },
        async add(adding) {
            const response = await fetch("./erp/api/v0/products/warehouses/", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(adding)
            });

            if (response.ok) {
                const added = await response.json();
                this.warehouses.push(added);
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        },
        async del(id) {
            const response = await fetch(
                `./erp/api/v0/products/warehouses/${id}`,
                { method: "DELETE" }
            );

            if (response.ok) {
                let index = this.warehouses.findIndex((w) => w.id === id);
                if (index !== -1) {
                    this.warehouses.splice(index, 1);
                }
            }
        },
        getById(id) {
            return this.warehouses.find((w) => w.id === id);
        },
        async save(id, data) {
            const response = await fetch(
                `./erp/api/v0/products/warehouses/${id}`,
                {
                    method: "PUT",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify(data)
                }
            );

            if (response.ok) {
                const newData = await response.json();
                const warehouse = this.warehouses.find((w) => w.id === id);
                this.fields.forEach((f) => {
                    warehouse[f] = newData[f];
                });
                warehouse.id = id; // prevent overwriting 'id'
            }
        }
    }
});
