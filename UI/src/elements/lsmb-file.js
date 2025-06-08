/** @format */

let lblCounter = 0;

function escHTML(s) {
    return s.replace(/[<>&"']/g, function (m) {
        return {
            "<": "&lt;",
            ">": "&gt;",
            '"': "&dquot;",
            "&": "&amp;",
            "'": "&#39;"
        }[m];
    });
}

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
            let elm = document.getElementById(this.elmId);
            if (elm) {
                if (newValue === null) {
                    document.getElementById(this.elmId).removeAttribute(name);
                } else {
                    document.getElementById(this.elmId).setAttribute(name, "");
                }
            }
        }
    }

    _connectedCallback() {
        let options = `type="file" id="${escHTML(this.elmId)}"`;
        let label = "";
        if (this.hasAttribute("name")) {
            options += ` name="${escHTML(this.getAttribute("name"))}"`;
        }
        if (this.required) {
            options += " required";
        }
        if (this.disabled) {
            options += " disabled";
        }
        if (this.hasAttribute("accept")) {
            options += ` accept="${escHTML(this.getAttribute("accept"))}"`;
        }
        if (this.hasAttribute("label")) {
            label = `<label for="${escHTML(this.elmId)}">${escHTML(
                this.getAttribute("label")
            )}</label>`;
        }
        this.innerHTML = `${label}<span><input ${options}></span>`;
        this.addEventListener("focus", () => {
            document.getElementById(this.elmId).focus();
        });
    }
}

customElements.define("lsmb-file", LsmbFile);
