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
        this.appendChild(this.dojoWidget.domNode);
        this.addEventListener("focus", () => {
            this.dojoWidget.focus();
        });
    }

    disconnectedCallback() {
        if (this.dojoWidget) {
            registry.remove(this.dojoWidget.id);
        }
    }
}

customElements.define("lsmb-button", LsmbButton);
