/** @format */
const Button = require("dijit/form/Button");
const registry = require("dijit/registry");

export class LsmbButton extends HTMLElement {
    dojoWidget = null;

    label = null;

    constructor() {
        super();
    }

    adoptedCallback() {
        if (this.dojoWidget && this.dojoWidget.resize) {
            this.dojoWidget.resize();
        }
    }

    connectedCallback() {
        this.label = this.innerHTML;
        this.innerHTML = "";
        let props = { label: this.label };

        this.dojoWidget = new Button(props);
        this.appendChild(this.dojoWidget.domNode);
    }

    disconnetedCallback() {
        if (this.dojoWidget) {
            registry.remove(this.dojoWidget.id);
        }
    }
}

customElements.define("lsmb-button", LsmbButton);
