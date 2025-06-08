/** @format */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoRadioButton = require("dijit/form/RadioButton");
const on = require("dojo/on");
const topic = require("dojo/topic");

export class LsmbRadioButton extends LsmbBaseInput {
    _valueAttrs() {
        return [...super._valueAttrs(), "checked", "topic"];
    }

    _rmAttrs() {
        return [...super._rmAttrs(), "checked"];
    }

    _widgetClass() {
        return dojoRadioButton;
    }

    _connectedCallback() {
        super._connectedCallback();
        if (this.dojoWidget) {
            let props = this._collectProps();
            if (props.topic) {
                this.dojoWidget.own(
                    on(this.dojoWidget.domNode, "change", () => {
                        if (this.dojoWidget.checked) {
                            topic.publish(props.topic, props.value);
                        }
                    })
                );
            }
        }
    }
}

customElements.define("lsmb-radio", LsmbRadioButton);
