/** @format */

let lblCounter = 0;

export class LsmbFile extends HTMLElement {
    constructor() {
        super();
    }

    connectedCallback() {
        let elmId = `/lsmb/form/file-${lblCounter++}`;
        let options = `type="file" id="${elmId}"`;
        let label = "";
        if (this.hasAttribute("name")) {
            options += ` name="${this.getAttribute("name")}"`;
        }
        if (this.hasAttribute("accept")) {
            options += ` accept="${this.getAttribute("accept")}"`;
        }
        if (this.hasAttribute("label")) {
            label = `<label for="${elmId}">${this.getAttribute(
                "label"
            )}</label>`;
        }
        this.innerHTML = `${label}<span><input ${options}></span>`;
    }
}

customElements.define("lsmb-file", LsmbFile);
