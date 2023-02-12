/** @format */
/* eslint-disable class-methods-use-this */

import { LsmbText } from "@/elements/lsmb-text";

export class LsmbPassword extends LsmbText {
    _stdProps() {
        return {
            ...super._stdProps(),
            type: "password"
        };
    }

    constructor() {
        super();
    }
}

customElements.define("lsmb-password", LsmbPassword);
