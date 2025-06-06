/** @format */

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
        return [
            "label",
            "label-position",
            "title",
            "name",
            "value",
            "tabindex",
            "size"
        ];
    }

    _rmAttrs() {
        return ["label", "title", "name", "value", "tabindex", "size"];
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

    _connectedCallback() {
        if (this.connected) {
            return;
        }
        this.connected = true;

        let id = this.getAttribute("id");
        this.removeAttribute("id");

        let props = this._collectProps();
        if (id) {
            props.id = id;
        }
        if (!this.dojoWidget) {
            this.dojoWidget = new (this._widgetClass())(props);
        }

        if (Object.hasOwn(props, "label") && props.label !== "_none_") {
            this.dojoLabel = document.createElement("label");
            this.dojoLabel.innerHTML = props.label;
            this.dojoLabel.classList.add("label");
            this.dojoLabel.setAttribute("for", this.dojoWidget.id);

            // without this handler, we bubble 2 events "to the outside"
            this.dojoLabel.addEventListener("click", (e) =>
                e.stopPropagation()
            );
        }

        const labelBefore =
            !Object.hasOwn(props, "label-position") ||
            props["label-position"] !== "after";

        if (labelBefore && this.dojoLabel) {
            this._labelRoot().appendChild(this.dojoLabel);
        }

        if (id) {
            this.dojoWidget.focusNode.setAttribute("id", id);
        }
        this.dojoWidget.placeAt(this._widgetRoot());

        if (!labelBefore && this.dojoLabel) {
            this._labelRoot().appendChild(this.dojoLabel);
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
