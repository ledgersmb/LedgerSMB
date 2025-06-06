/** @format */
// eslint-disable class-methods-use-this

export class LsmbDijit extends HTMLElement {
    dojoWidget = null;
    collectedProps = null;

    constructor() {
        super();
    }

    _boolAttrs() {
        return ["disabled"];
    }

    _valueAttrs() {
        return [];
    }

    _rmAttrs() {
        return [];
    }

    _stdProps() {
        return {};
    }

    _collectProps() {
        if (this._collectedProps) {
            return this._collectedProps;
        }
        let extra = this.hasAttribute("dojo-props")
            ? eval("({" + this.getAttribute("dojo-props") + "})") // eslint-disable-line no-eval
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

        this._collectedProps = props;
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

    connectedCallback() {
        this._connectedCallback();
        this._rmAttrs().forEach((prop) => {
            if (this.hasAttribute(prop)) {
                this.removeAttribute(prop);
            }
        });
    }
}
