/** @format */

import { LsmbText } from "@/elements/lsmb-text";

export class LsmbPassword extends LsmbText {
    _stdProps() {
        return { type: "password" };
    }

    constructor() {
        super();
    }
}

customElements.define("lsmb-password", LsmbPassword);
