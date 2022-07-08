/** @format */

import { defineStore } from "pinia";
import { configStoreTemplate } from "@/store/configTemplate";

export const useGIFIsStore = defineStore("gifis", {
    ...configStoreTemplate,
    state: () => {
        return {
            fields: ["accno", "description"],
            id: "accno",
            items: [],
            url: "gl/gifi/"
        };
    }
});
