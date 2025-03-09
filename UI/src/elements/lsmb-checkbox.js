/** @format */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoCheckBox = require("dijit/form/CheckBox");

export class LsmbCheckBox extends LsmbBaseInput {
    _widgetClass() {
        return dojoCheckBox;
    }
}

customElements.define("lsmb-checkbox", LsmbCheckBox);
