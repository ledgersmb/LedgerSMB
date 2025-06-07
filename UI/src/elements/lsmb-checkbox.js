/** @format */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoCheckBox = require("dijit/form/CheckBox");
const on = require("dojo/on");
const topic = require("dojo/topic");

export class LsmbCheckBox extends LsmbBaseInput {
    _valueAttrs() {
        return [...super._valueAttrs(), "checked", "topic"];
    }

    _rmAttrs() {
        return [...super._rmAttrs(), "checked"];
    }

    _widgetClass() {
        return dojoCheckBox;
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
                        } else {
                            topic.publish(props.topic, null);
                        }
                    })
                );
            }
        }
    }
}

customElements.define("lsmb-checkbox", LsmbCheckBox);
