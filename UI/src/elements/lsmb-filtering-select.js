/** @format */
/* eslint-disable class-methods-use-this, max-classes-per-file */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoSelect = require("lsmb/FilteringSelect");

export class LsmbFilteringSelect extends LsmbBaseInput {
    _widgetClass() {
        return dojoSelect;
    }
}

customElements.define("lsmb-filtering-select", LsmbFilteringSelect);
