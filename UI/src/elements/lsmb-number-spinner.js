/** @format */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoNumberSpinner = require("dijit/form/NumberSpinner");

export class LsmbNumberSpinner extends LsmbBaseInput {
    _valueAttrs() {
        return [...super._valueAttrs(), "min", "max", "places"];
    }

    _rmAttrs() {
        return [...super._rmAttrs(), "min", "max", "places"];
    }

    _widgetClass() {
        return dojoNumberSpinner;
    }

    _collectProps() {
        if (this._collectedProps) {
            return this._collectedProps;
        }
        let props = super._collectProps();
        props.intermediateChanges = true;
        props.constraints = {
            max: +props.max, // string-to-number conversion
            min: +props.min,
            places: +props.places
        };
        delete props.max;
        delete props.min;
        delete props.places;
        return props;
    }
}

customElements.define("lsmb-number-spinner", LsmbNumberSpinner);
