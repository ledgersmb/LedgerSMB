/** @format */
/* eslint-disable class-methods-use-this */

import { LsmbDijit } from "@/elements/lsmb-dijit";

const registry = require("dijit/registry");

export class LsmbBaseInput extends LsmbDijit {

    dojoLabel = null;
    connected = false;

    constructor() {
        super();
    }

    _boolAttrs() {
        return ["disabled", "readonly", "required"];
    }

    _valueAttrs() {
        return ["label", "title", "name", "value", "tabindex"];
    }

    _labelRoot() {
        return this;
    }

    _widgetRoot() {
        return this;
    }

    _widgetClass() {
        throw new Error(
            "lsmb-base-input is an abstract base class! don't use directly!"
        );
    }

    static get observedAttributes() {
        /* "disabled" prop is inherited */
        return ["disabled", "readonly", "required", "value"];
    }

    get readonly() {
        return this.hasAttribute("readonly");
    }

    set readonly(newValue) {
        if (newValue) {
            this.setAttribute("readonly", "");
        } else {
            this.removeAttribute("readonly");
        }
    }

    get required() {
        return this.hasAttribute("required");
    }

    set required(newValue) {
        if (newValue) {
            this.setAttribute("required", "");
        } else {
            this.removeAttribute("required");
        }
    }

    get value() {
        return this.getAttribute("value");
    }

    set value(newValue) {
        this.setAttribute("value", newValue);
    }

    connectedCallback() {
        if (this.connected) {
            return;
        }
        this.connected = true;

        let props = this._collectProps();
        if (this.hasAttribute('id')) {
            // move the ID property to the widget we're creating
            // in order to correctly link any labels
            props.id = this.getAttribute('id');
            this.removeAttribute('id');
        }
        let widgetElm = document.createElement("span");
        [ ...this.children ].forEach((c) => { widgetElm.appendChild(c); });
        this._widgetRoot().appendChild(widgetElm);
        this.dojoWidget = new (this._widgetClass())(props, widgetElm);

        if (
            this.hasAttribute("label") &&
            this.getAttribute("label") !== "_none_"
        ) {
            this.dojoLabel = document.createElement("label");
            this.dojoLabel.innerHTML = this.getAttribute("label");
            this.dojoLabel.classList.add("label");
            this.dojoLabel.setAttribute('for', props.id);

            // without this handler, we bubble 2 events "to the outside"
            this.dojoLabel.addEventListener("click", (e) =>
                e.stopPropagation()
            );

            const labelBefore =
                  !this.hasAttribute("label-pos") ||
                this.getAttribute("label-pos") !== "after";

            // using 'firstChild', because Dojo replaced widgetElm...
            if (labelBefore) {
                this._widgetRoot().insertBefore(this.dojoLabel, this.firstChild);
            }
            else {
                this._widgetRoot().insertAfter(this.dojoLabel, this.firstChild);
            }
        }

        this.dojoWidget.on("input", (e) => {
            let evt = new InputEvent("input", {
                data: e.charOrCode
            });
            this.dispatchEvent(evt);
        });
        this.dojoWidget.on("change", () => {
            let evt = new Event("change");
            this.dispatchEvent(evt);
        });
        this.addEventListener("focus", () => {
            this.dojoWidget.focus();
        });
    }

    disconnectedCallback() {
        this.connected = false;
        if (this.dojoWidget) {
            registry.remove(this.dojoWidget.id);
            this.dojoWidget.destroy(false);
            this.dojoWidget = null;
        }

        if (this.dojoLabel) {
            this.dojoLabel.remove();
            this.dojoLabel = null;
        }
    }
}
