/** @format */

let lblCounter = 0;

export class LsmbFile extends HTMLElement {
    elmId = `/lsmb/form/file-${lblCounter++}`;

    constructor() {
        super();
    }

    static get observedAttributes() {
        return ["disabled", "required"];
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

    attributeChangedCallback(name, oldValue, newValue) {
        if (oldValue === newValue) {
            return;
        }

        if (name === "disabled" || name === "required") {
            if (newValue === null) {
                document.getElementById(this.elmId).removeAttribute(name);
            } else {
                document.getElementById(this.elmId).setAttribute(name, "");
            }
        }
    }

    connectedCallback() {
        let options = `type="file" id="${this.elmId}"`;
        let label = "";
        if (this.hasAttribute("name")) {
            options += ` name="${this.getAttribute("name")}"`;
        }
        if (this.hasAttribute("accept")) {
            options += ` accept="${this.getAttribute("accept")}"`;
        }
        if (this.hasAttribute("label")) {
            label = `<label for="${this.elmId}">${this.getAttribute(
                "label"
            )}</label>`;
        }
        this.innerHTML = `${label}<span><input ${options}></span>`;
        this.addEventListener("focus", () => {
            document.getElementById(this.elmId).focus();
        });
    }
}

customElements.define("lsmb-file", LsmbFile);
