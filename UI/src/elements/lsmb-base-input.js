/** @format */
/* eslint-disable class-methods-use-this */

const registry = require("dijit/registry");

export class LsmbBaseInput extends HTMLElement {
    dojoWidget = null;

    dojoLabel = null;

    constructor() {
        super();

    }

    _boolAttrs() {
        return ["disabled", "readonly", "required"];
    }

    _valueAttrs() {
        return ["title", "name", "value", "tabindex"];
    }

    _stdProps() {
        return {};
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

    adoptedCallback() {
        if (this.dojoWidget && this.dojoWidget.resize) {
            this.dojoWidget.resize();
        }
    }

    connectedCallback() {
        /* eslint-disable no-eval */
        let extra = this.hasAttribute("dojo-props")
            ? eval("({" + this.getAttribute("dojo-props") + "})")
            : {};
        let props = { ...extra, ...this._stdProps() };
        this._valueAttrs().forEach((prop) => {
            if (this.hasAttribute(prop)) {
                props[prop] = this.getAttribute(prop);
            }
        });
        this._boolAttrs().forEach((prop) => {
            if (this.hasAttribute(prop)) {
                props[prop] = true;
            }
        });
        if (props.name && !props.id) {
            props.id = props.name.replace(/[^a-zA-Z0-9]/, "-");
        }
        this.dojoWidget = new (this._widgetClass())(props);
        ["name", "id", "tabindex"].forEach((att) => this.removeAttribute(att));

        if (this.hasAttribute("title") && !this.hasAttribute("label")) {
            this.setAttribute("label", this.getAttribute("title"));
        }
        if (
            this.hasAttribute("label") &&
            this.getAttribute("label") !== "_none_"
        ) {
            this.dojoLabel = document.createElement("label");
            this.dojoLabel.innerHTML = this.getAttribute("label");
            this.dojoLabel.classList.add("label");
        }
        const labelBefore =
            !this.hasAttribute("label-pos") ||
            this.getAttribute("label-pos") !== "after";
        if (labelBefore && this.dojoLabel) {
            this._labelRoot().appendChild(this.dojoLabel);
        }

        this.dojoWidget.placeAt(this._widgetRoot());
        if (!labelBefore && this.dojoLabel) {
            this._labelRoot().appendChild(this.dojoLabel);
        }
        if (this.dojoLabel) {
            this.dojoLabel.setAttribute("for", this.dojoWidget.id);
        }
    }

    disconnectedCallback() {
        if (this.dojoWidget) {
            registry.remove(this.dojoWidget.id);
        }
    }
}
