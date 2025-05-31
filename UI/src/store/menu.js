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
                    n.selectable = !n.menu;
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
        tree: (state) => {
            if (state._tree) {
                return state._tree;
            }
            state.nodes.forEach((n) => {
                const children = state.nodes.filter((c) => c.parent === n.id);
                if (children.length > 0) {
                    n.children = children;
                }
            });
            state._tree = state.nodes.filter((n) => n.parent === 0);
            return state._tree;
        },
        children: (state) => (key) => {
            if (state.nodes === null) {
                return [];
            }

            return state.nodes.filter((n) => n.parent === key);
        }
    }
});
