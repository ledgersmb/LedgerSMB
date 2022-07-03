/** @format */

import { defineStore } from "pinia";

export const useSessionUserStore = defineStore("sessionUser", {
    state: () => {
        return {
            session: {
                roles: [],
                preferences: {}
            }
        };
    },
    actions: {
        async initialize() {
            const response = await fetch("./erp/api/v0/session", {
                method: "GET"
            });

            if (response.ok) {
                let data = await response.json();
                console.log(data);
                this.session = data;
            } else {
                throw new Error(`HTTP Error: ${response.status}`);
            }
        }
    },
    getters: {
        hasRole: (state) => {
            return (role) =>
                state.session.roles.find(r => r === role) !== undefined;
        }
    }
});
