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
                added._meta = {
                    ETag: response.headers.get("ETag")
                };
                this.warehouses.push(added);
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        },
        async del(id) {
            const warehouse = this.getById(id);
            const response = await fetch(
                `./erp/api/v0/products/warehouses/${id}`,
                {
                    method: "DELETE",
                    headers: {
                        "If-Match": warehouse._meta.ETag
                    }
                }
            );

            if (response.ok) {
                let index = this.warehouses.findIndex((w) => w.id === id);
                if (index !== -1) {
                    this.warehouses.splice(index, 1);
                }
            }
        },
        async get(id) {
            const index = this.warehouses.findIndex((w) => w.id === id);
            const warehouse = this.warehouses[index];
            if (!warehouse._meta || warehouse._meta.invalidated) {
                const response = await fetch(
                    `./erp/api/v0/products/warehouses/${id}`,
                    { method: "GET" }
                );

                if (response.ok) {
                    const newData = await response.json();
                    newData.id = id;
                    newData._meta = {
                        ETag: response.headers.get("ETag")
                    };
                    this.warehouses[index] = newData;
                }
            }

            return this.warehouses[index];
        },
        getById(id) {
            return id === -1 ? {} : this.warehouses.find((w) => w.id === id);
        },
        async save(id, data) {
            const warehouse = this.getById(id);
            const response = await fetch(
                `./erp/api/v0/products/warehouses/${id}`,
                {
                    method: "PUT",
                    headers: {
                        "Content-Type": "application/json",
                        "If-Match": warehouse._meta.ETag
                    },
                    body: JSON.stringify(data)
                }
            );

            if (response.ok) {
                const newData = await response.json();
                const index = this.warehouses.findIndex((w) => w.id === id);
                newData.id = id; // prevent overwriting 'id'
                this.warehouses[index] = newData;
            }
        }
    }
});
