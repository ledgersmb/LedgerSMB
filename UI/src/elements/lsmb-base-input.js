/** @format */
/* eslint-disable class-methods-use-this */

const registry = require("dijit/registry");

export class LsmbBaseInput extends HTMLElement {
    dojoWidget = null;

    dojoLabel = null;

    connected = false;

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

    static get observedAttributes() {
        return ["value"];
    }

    get value() {
        return this.getAttribute("value");
    }

    set value(newValue) {
        this.setAttribute("value", newValue);
    }

    adoptedCallback() {
        if (this.dojoWidget && this.dojoWidget.resize) {
            this.dojoWidget.resize();
        }
    }

    attributeChangedCallback(name, oldValue, newValue) {
        if (oldValue === newValue || !this.dojoWidget) return;
        this.dojoWidget.set(name, newValue);
    }

    connectedCallback() {
        if (this.connected) {
            return;
        }
        this.connected = true;

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
        this.dojoWidget = new (this._widgetClass())(props);

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

            // without this handler, we bubble 2 events "to the outside"
            this.dojoLabel.addEventListener("click", (e) =>
                e.stopPropagation()
            );
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

            this.dojoLabel.remove();
            this.dojoLabel = null;
        }
    }
}
