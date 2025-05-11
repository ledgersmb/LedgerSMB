/** @format */

import { defineStore } from "pinia";

export const useMenuStore = defineStore("menu", {
    state: () => {
        return {
            nodes: null
        };
    },
    actions: {
        async initialize() {
            const response = await fetch("./erp/api/v0/menu-nodes", {
                method: "GET"
            });

            if (response.ok) {
                const rv = await response.json();
                this.nodes = rv;
                this.nodes.forEach((n) => {
                    n.expandable = n.menu;
                    n.lazy = n.menu;
                    n.selectable = !n.menu;
                    // n.handler = () => alert("clicked");
                });
            }
        }
    },
    getters: {
        toplevelNodes: (state) => {
            if (state.nodes === null) {
                return [];
            }

            return state.nodes.filter((n) => n.parent === 0);
        },
        nodeById: (state) => (id) => {
            return state.nodes.find((n) => n.id === id);
        },
        children: (state) => (key) => {
            if (state.nodes === null) {
                return [];
            }

            return state.nodes.filter((n) => n.parent === key);
        }
    }
});
