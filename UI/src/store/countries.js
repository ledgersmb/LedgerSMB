/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

export const useCountriesStore = defineStore("countries", {
    ...configStoreTemplate,
    state: () => {
        return {
            fields: ["short_name", "name"],
            id: "short_name",
            items: [],
            _links: [],
            url: "countries"
        };
    }
});
