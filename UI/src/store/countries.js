/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

let { actions: configActions, getters: configGetters } = configStoreTemplate;

export const useCountriesStore = defineStore("countries", {
    ...configStoreTemplate,
    getters: {
        ...configGetters,
        default: (state) => state.items.find((elm) => elm.default),
    },
    actions: {
        ...configActions,
        async setDefault(id) {
            const oldDefault = this.default;
            if (oldDefault && oldDefault[this.id] === id) {
                return;
            }

            const country = this.getById(id);
            await this.save(id, { ...country, default: true });
            if (oldDefault) {
                oldDefault.default = false; // remove the old default
            }
        }
    },
    state: () => {
        return {
            fields: [ "_meta", "code", "default", "name"],
            id: "code",
            items: [],
            _links: [],
            url: "countries"
        };
    }
});
