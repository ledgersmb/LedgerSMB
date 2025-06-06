/** @format */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoRadioButton = require("dijit/form/RadioButton");

export class LsmbRadioButton extends LsmbBaseInput {
    _valueAttrs() {
        return [...super._valueAttrs(), "checked"];
    }

    _rmAttrs() {
        return [...super._rmAttrs(), "checked"];
    }

    _widgetClass() {
        return dojoRadioButton;
    }
}

customElements.define("lsmb-radio", LsmbRadioButton);
