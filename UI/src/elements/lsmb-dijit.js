/** @format */
/* eslint-disable class-methods-use-this */

export class LsmbDijit extends HTMLElement {
    dojoWidget = null;

    constructor() {
        super();
    }

    _boolAttrs() {
        return ["disabled"];
    }

    _valueAttrs() {
        return [];
    }

    _stdProps() {
        return {};
    }

    _collectProps() {
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

        return props;
    }

    static get observedAttributes() {
        return ["disabled"];
    }

    get disabled() {
        return this.hasAttribute("disabled");
    }

    set disabled(newValue) {
        if (newValue) {
            this.setAttribute("disabled", "");
        } else {
            this.removeAttribute("disabled");
        }
    }

    adoptedCallback() {
        if (this.dojoWidget && this.dojoWidget.resize) {
            this.dojoWidget.resize();
        }
    }

    attributeChangedCallback(name, oldValue, newValue) {
        if (oldValue === newValue || !this.dojoWidget) {
            return;
        }

        if (this._boolAttrs().includes(name)) {
            this.dojoWidget.set(name, newValue !== null);
        } else {
            this.dojoWidget.set(name, newValue);
        }
    }
}
