/** @format */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const lsmbAccountSelector = require("lsmb/accounts/AccountSelector");

export class LsmbAccountSelect extends LsmbBaseInput {
    widgetWrapper = null;

    _stdProps() {
        return { size: 10, required: false };
    }

    _widgetClass() {
        return lsmbAccountSelector;
    }

    _collectProps() {
        let props = super._collectProps();
        props.options = [];
        for (const child of this.children) {
            props.options.push({
                label: child.innerHTML,
                value: child.getAttribute("value")
            });
        }
        this.replaceChildren(); // delete all children
        return props;
    }
}

customElements.define("lsmb-account-select", LsmbAccountSelect);
