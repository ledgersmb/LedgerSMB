/** @format */
/* eslint-disable class-methods-use-this, max-classes-per-file */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoTextBox = require("dijit/form/ValidationTextBox");

export class LsmbText extends LsmbBaseInput {
    _stdProps() {
        return {
            ...super._stdProps(),
            size: 60,
            type: "text"
        };
    }

    _valueAttrs() {
        return [...super._valueAttrs(), "size", "maxlength", "autocomplete"];
    }

    _widgetClass() {
        return dojoTextBox;
    }
}

customElements.define("lsmb-text", LsmbText);
