/** @format */

export const configStoreTemplate = {
    // to be mixed in at the parent level:
    // state: () => {
    //    return {
    //        "fields": ["id", "description"],
    //        "items": [],
    //        "_links": [],
    //        "url": "products/warehouses/"
    //    };
    // },
    getters: {
        apiURL: (state) => `/erp/api/v0/${state.url}`
    },
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
            const warehouse = this.getById(id);
            const response = await fetch(`./erp/api/v0/${this.url}/${id}`, {
                method: "DELETE",
                headers: {
                    "If-Match": warehouse._meta.ETag
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
        async get(id) {
            let index = this.items.findIndex((w) => w[this.id] === id);
            if (index === -1) {
                index = this.items.length;
            }
            const warehouse = this.items[index];
            if (!warehouse || !warehouse._meta || warehouse._meta.invalidated) {
                const response = await fetch(`./erp/api/v0/${this.url}/${id}`, {
                    method: "GET"
                });

                if (response.ok) {
                    const newData = await response.json();
                    newData[this.id] = id;
                    newData._meta = {
                        ETag: response.headers.get("ETag")
                    };
                    this.items[index] = newData;
                } else {
                    throw new Error(`HTTP Error: ${response.status}`);
                }
            }

            return this.items[index];
        },
        getById(id) {
            if (id === "") {
                const rv = {};
                this.fields.forEach((f) => {
                    rv[f] = undefined;
                });
                return rv;
            }
            return this.items.find((w) => w[this.id] === id);
        },
        async save(id, data) {
            const warehouse = this.getById(id);
            const response = await fetch(`./erp/api/v0/${this.url}/${id}`, {
                method: "PUT",
                headers: {
                    "Content-Type": "application/json",
                    "If-Match": warehouse._meta.ETag
                },
                body: JSON.stringify(data)
            });

            if (response.ok) {
                const newData = await response.json();
                const index = this.items.findIndex((w) => w[this.id] === id);
                newData[this.id] = id; // prevent overwriting 'id'
                newData._meta = {
                    ETag: response.headers.get("ETag")
                };
                this.items[index] = newData;
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        }
    }
};
