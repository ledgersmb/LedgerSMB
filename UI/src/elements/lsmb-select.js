/** @format */
/* eslint-disable class-methods-use-this, max-classes-per-file */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoSelect = require("dijit/form/Select");

export class LsmbSelect extends LsmbBaseInput {
    _widgetClass() {
        return dojoSelect;
    }
}

customElements.define("lsmb-select", LsmbSelect);
