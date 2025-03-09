/** @format */

import { LsmbDijit } from "@/elements/lsmb-dijit";

const Button = require("dijit/form/Button");
const registry = require("dijit/registry");

export class LsmbButton extends LsmbDijit {
    label = null;

    constructor() {
        super();
    }

    _valueAttrs() {
        return ["type"];
    }

    connectedCallback() {
        this.label = this.innerHTML;
        this.innerHTML = "";
        let props = this._collectProps();
        props.label = this.label;

        this.dojoWidget = new Button(props);
        this.dojoWidget.placeAt(this);
        this.addEventListener("focus", () => {
            this.dojoWidget.focus();
        });
    }

    disconnectedCallback() {
        if (this.dojoWidget) {
            this.innerHTML = this.label;
            registry.remove(this.dojoWidget.id);
            this.dojoWidget.destroy(false);
            this.dojoWidget = null;
        }
    }
}

customElements.define("lsmb-button", LsmbButton);
