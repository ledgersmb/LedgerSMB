/** @format */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoDateBox = require("lsmb/DateTextBox");

export class LsmbDate extends LsmbBaseInput {
    widgetWrapper = null;

    _stdProps() {
        return { size: 10 };
    }

    _widgetRoot() {
        if (this.widgetWrapper) {
            return this.widgetWrapper;
        }
        this.widgetWrapper = document.createElement("span");
        this.appendChild(this.widgetWrapper);

        return this.widgetWrapper;
    }

    _widgetClass() {
        return dojoDateBox;
    }

    disconnectedCallback() {
        if (this.widgetWrapper) {
            this.widgetWrapper.remove();
            this.widgetWrapper = null;
        }
        super.disconnectedCallback();
    }
}

customElements.define("lsmb-date", LsmbDate);
