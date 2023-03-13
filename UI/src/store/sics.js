/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

export const useSICsStore = defineStore("sics", {
    ...configStoreTemplate,
    state: () => {
        return {
            fields: ["code", "sictype", "description"],
            id: "code",
            items: [],
            _links: [],
            url: "contacts/sic"
        };
    }
});
