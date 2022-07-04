/** @format */

import { defineStore } from "pinia";

export const useSessionUserStore = defineStore("sessionUser", {
    state: () => {
        return {
            roles: [],
            preferences: {}
        };
    },
    actions: {
        async initialize() {
            const response = await fetch("./erp/api/v0/session", {
                method: "GET"
            });

            if (response.ok) {
                let data = await response.json();
                this.$patch({
                    roles: data.roles,
                    preferences: data.preferences
                });
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        }
    },
    getters: {
        hasRole: (state) => {
            return (role) => state.roles.find((r) => r === role) !== undefined;
        }
    }
});
