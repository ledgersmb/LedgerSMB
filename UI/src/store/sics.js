/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

export const useSICsStore = defineStore("sics", {
    ...configStoreTemplate,
    state: () => {
        return {
            fields: ["code", "description"],
            id: "code",
            items: [],
            url: "contacts/sic/"
        };
    }
});
