/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

export const useLanguagesStore = defineStore("languages", {
    ...configStoreTemplate,
    state: () => {
        return {
            fields: ["code", "description"],
            id: "code",
            items: [],
            url: "languages"
        };
    }
});
