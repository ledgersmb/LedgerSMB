
const registry = require("dijit/registry");
const dojoTextBox = require("dijit/form/TextBox");

class LsmbText extends HTMLElement {
    dojoWidget = null;

    constructor() {
        super();
    }
    adoptedCallback() {
        if (this.dojoWidget
            && this.dojoWidget.resize) {
            this.dojoWidget.resize();
        }
    }
    connectedCallback() {
        if (this.dojoWidget) {
            if (registry.byId(this.dojoWidget.id) !== this.dojoWidget) {
                registry.add(this.dojoWidget);
            }
            return;
        }
        let root = this;
        let extra =
            this.hasAttribute('dojo-props') ?
            eval('({'+this.getAttribute('dojo-props')+'})') : {};
        let props = { ...extra };
        ["title", "name", "size", "value"]
            .forEach((prop) => {
                if (this.hasAttribute(prop)) {
                    props[prop] = this.getAttribute(prop);
                };
            });
        if (this.hasAttribute('disabled')) {
            props['disabled'] = true;
        }
        if (this.hasAttribute('required')) {
            props['required'] = true;
        }
        if (props["name"] && !props["id"]) {
            props["id"] = props["name"];
        }
        if (props["id"]) {
            registry.remove(props["id"]);
        }
        this.dojoWidget = new dojoTextBox(props);

        let label;
        const labelBefore = !this.hasAttribute('label-pos')
              || this.getAttribute('label-pos') !== "after";
        if (this.hasAttribute('label')
            && this.getAttribute('label') !== "_none_") {
            label = document.createElement('label');
            label.innerHTML = this.getAttribute('label');
            label.classList.add('label');
            if (labelBefore) {
                root.appendChild(label);
            }
        }

        this.dojoWidget.placeAt(root);
        if (!labelBefore && label) {
            this.appendChild(label);
        }
        if (label) {
            label.setAttribute('for', this.dojoWidget.id);
        }
    }
    disconnectedCallback() {
        if (this.dojoWidget) {
            registry.remove(this.dojoWidget.id);
        }
    }
}

customElements.define("lsmb-text", LsmbText);

