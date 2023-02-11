/** @format */
/* eslint-disable class-methods-use-this, max-classes-per-file */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

export class LsmbBaseChecked extends LsmbBaseInput {

    static get observedAttributes() {
        /* all but "checked" prop are inherited */
        return ["disabled", "readonly", "required", "value", "checked"];
    }

    _boolAttrs() {
        return ["disabled", "readonly", "required", "checked"];
    }

    get checked() {
        return this.hasAttribute("checked");
    }

    set checked(newValue) {
        if (newValue) {
            this.setAttribute("checked", "");
        } else {
            this.removeAttribute("checked");
        }
    }
}
