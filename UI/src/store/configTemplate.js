/** @format */

export const configStoreTemplate = {
    // to be mixed in at the parent level:
    // state: () => {
    //    return {
    //        fields: ["id", "description"],
    //        items: [],
    //        url: "products/warehouses/"
    //    };
    // },
    actions: {
        async initialize() {
            const response = await fetch(`./erp/api/v0/${this.url}`, {
                method: "GET"
            });

            if (response.ok) {
                this.items = await response.json();
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
            const response = await fetch(`./erp/api/v0/${this.url}${id}`, {
                method: "DELETE",
                headers: {
                    "If-Match": warehouse._meta.ETag
                }
            });

            if (response.ok) {
                let index = this.items.findIndex((w) => w.id === id);
                if (index !== -1) {
                    this.items.splice(index, 1);
                }
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        },
        async get(id) {
            const index = this.items.findIndex((w) => w.id === id);
            const warehouse = this.items[index];
            if (!warehouse._meta || warehouse._meta.invalidated) {
                const response = await fetch(`./erp/api/v0/${this.url}${id}`, {
                    method: "GET"
                });

                if (response.ok) {
                    const newData = await response.json();
                    newData.id = id;
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
            return id === ""
                ? { id: undefined, description: undefined }
                : this.items.find((w) => w.id === id);
        },
        async save(id, data) {
            const warehouse = this.getById(id);
            const response = await fetch(`./erp/api/v0/${this.url}${id}`, {
                method: "PUT",
                headers: {
                    "Content-Type": "application/json",
                    "If-Match": warehouse._meta.ETag
                },
                body: JSON.stringify(data)
            });

            if (response.ok) {
                const newData = await response.json();
                const index = this.items.findIndex((w) => w.id === id);
                newData.id = id; // prevent overwriting 'id'
                this.items[index] = newData;
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        }
    }
};
