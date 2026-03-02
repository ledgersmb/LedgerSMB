/** @format */
/* global lsmbConfig */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoDateLocale = require("dojo/date/locale");
const dojoDateBox = require("lsmb/DateTextBox");
const isoDate = /^\d\d\d\d-\d\d-\d\d$/;

export class LsmbDate extends LsmbBaseInput {
    widgetWrapper = null;

    _stdProps() {
        return { size: 10 };
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

    _collectProps() {
        let props = super._collectProps();
        if (props.value === "today") {
            props.value = new Date();
        } else if (typeof props.value === typeof "") {
            if (isoDate.test(props.value)) {
                props.value = dojoDateLocale.parse(props.value, {
                    datePattern: "yyyy-MM-dd",
                    selector: "date"
                });
            } else {
                props.value = dojoDateLocale.parse(props.value, {
                    datePattern: lsmbConfig.dateformat.replace(/mm/, "MM"),
                    selector: "date"
                });
            }
        }
        return props;
    }

    disconnectedCallback() {
        if (this.widgetWrapper) {
            this.widgetWrapper.remove();
            this.widgetWrapper = null;
        }
        super.disconnectedCallback();
    }
}

customElements.define("lsmb-date", LsmbDate);
