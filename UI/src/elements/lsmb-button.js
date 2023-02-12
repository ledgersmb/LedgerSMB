/** @format */
/* eslint-disable class-methods-use-this */

import { LsmbDijit } from "@/elements/lsmb-dijit";

const Button = require("dijit/form/Button");
const registry = require("dijit/registry");

export class LsmbButton extends LsmbDijit {
    static idRegex = /[^\p{IsAlnum}]/g;

    label = null;

    constructor() {
        super();
    }

    _valueAttrs() {
        return ["name", "type", "value"];
    }

    connectedCallback() {
        this.label = this.innerHTML;
        this.innerHTML = "";
        let props = this._collectProps();
        props.label = this.label;
        if (this.hasAttribute('id')) {
            // move the ID property to the widget we're creating
            // in order to correctly link any labels
            props.id = this.getAttribute('id');
            this.removeAttribute('id');
        }
        if (!props.id && props.name && props.value) {
            /* eslint-disable no-param-reassign */
            props.id = (props.name + "-" + props.value).replaceAll(LsmbButton.idRegex, "-");
        }

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
