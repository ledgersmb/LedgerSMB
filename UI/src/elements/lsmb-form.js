/** @format */
/* eslint-disable class-methods-use-this */

import { LsmbDijit } from "@/elements/lsmb-dijit";

const Form  = require("lsmb/Form");
const registry = require("dijit/registry");
const parser = require("dojo/parser");

export class LsmbForm extends HTMLFormElement {

    formWidget = null;

    connectedCallback() {
        let props = {};
        props.method = this.method;
        props.action = this.action;
        props.id = this.id;
        this.formWidget = new Form(props, this);
    }

    disconnectedCallback() {
        if (this.formWidget) {
            registry.remove(this.formWidget.id);
            this.formWidget = null;
        }
    }
}

customElements.define("lsmb-form", LsmbForm, { extends: "form" });
