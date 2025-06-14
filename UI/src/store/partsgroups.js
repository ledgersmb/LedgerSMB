/** @format */

import { defineStore } from "pinia";

export const usePartsgroupsStore = defineStore("partsgroups", {
    actions: {
        async initialize() {
            const response = await fetch(`./erp/api/v0/${this.url}`, {
                method: "GET"
            });

            if (response.ok) {
                const rv = await response.json();
                this.items = rv.items;
                this._links = rv._links;
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        },
        async add(adding) {
            const response = await fetch(`./erp/api/v0/${this.url}`, {
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
                this.items.push(added);
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        },
        async del(id) {
            const partsgroup = this.getById(id);
            const response = await fetch(`./erp/api/v0/${this.url}/${id}`, {
                method: "DELETE",
                headers: {
                    "If-Match": `"${partsgroup._meta.ETag}"`
                }
            });

            if (response.ok) {
                let index = this.items.findIndex((w) => w[this.id] === id);
                if (index !== -1) {
                    this.items.splice(index, 1);
                }
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        },
        getById(id) {
            return this.items.find((w) => w.id === id);
        },
        async save(id, data) {
            const partsgroup = this.getById(id);
            const response = await fetch(`./erp/api/v0/${this.url}/${id}`, {
                method: "PUT",
                headers: {
                    "Content-Type": "application/json",
                    "If-Match": `"${partsgroup._meta.ETag}"`
                },
                body: JSON.stringify(data)
            });

            if (response.ok) {
                const newData = await response.json();
                const index = this.items.findIndex((w) => w.id === id);
                newData.id = id; // prevent overwriting 'id'
                newData._meta = {
                    ETag: response.headers.get("ETag")
                };
                this.items[index] = newData;
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        }
    },
    getters: {
        apiURL: (state) => `/erp/api/v0/${state.url}`,
        tree: (state) => {
            let byId = {};
            state.items.forEach((i) => {
                byId[i.id] = i;
                i.children = [];
            });
            state.items.forEach((i) => {
                if (i.parent) {
                    byId[i.parent].children.push(i);
                }
            });
            return state.items.filter((i) => !i.parent);
        }
    },
    state: () => {
        return {
            items: [],
            _links: [],
            url: "products/partsgroups"
        };
    }
});
