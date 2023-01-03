/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

export const useCountriesStore = defineStore("countries", {
    ...configStoreTemplate,
    state: () => {
        return {
            fields: ["code", "name"],
            id: "code",
            items: [],
            _links: [],
            url: "countries"
        };
    }
});
