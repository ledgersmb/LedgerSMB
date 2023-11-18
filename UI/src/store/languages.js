/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

let { actions: configActions, getters: configGetters } = configStoreTemplate;

export const useLanguagesStore = defineStore("languages", {
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

            const language = this.getById(id);
            await this.save(id, { ...language, default: true });
            if (oldDefault) {
                oldDefault.default = false; // remove the old default
            }
        }
    },
    state: () => {
        return {
            fields: ["_meta", "code", "default", "description"],
            id: "code",
            items: [],
            _links: [],
            url: "languages"
        };
    }
});
