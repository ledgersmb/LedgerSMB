
import { h } from "vue";
//import axios from "axios";

const registry = require("dijit/registry");
const parser   = require("dojo/parser");

export default {
    data() {
        return {
            uiURL: ''
        };
    },
    beforeRouteUpdate() {
    },
    beforeRouteLeave() {
    },
    mounted() {
    },
    render(createElement) {
        return h('div', { innerHTML: 'some <h1>text</h1>' });
    }
};
