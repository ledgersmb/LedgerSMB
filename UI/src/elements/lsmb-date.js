/** @format */
/* eslint-disable class-methods-use-this, max-classes-per-file */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoDateBox = require("lsmb/DateTextBox");

export class LsmbDate extends LsmbBaseInput {
    widgetWrapper = null;

    _stdProps() {
        return {
            ...super._stdProps(),
            size: 10
        };
    }

    _collectProps() {
        let props = super._collectProps();
        if ("value" in props && !props.value) {
            // a value of "" is interpreted as Unix 'epoch'
            // instead, we want it to be interpreted as 'empty'
            // so, delete the property
            delete props.value;
        }

        return props;
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
}

customElements.define("lsmb-date", LsmbDate);
