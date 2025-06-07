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
        return [...super._rmAttrs(), "checked", "topic"];
    }

    _widgetClass() {
        return dojoCheckBox;
    }

    _connectCallback() {
        super._connectCallback();
        if (this.dojoWidget) {
            let props = this._collectProps();
            if (props.topic) {
                this.dojoWidget.own(
                    on(this.dojoWidget.domNode, "change", () => {
                        if (this.checked) {
                            topic.publish(props.topic, props.value);
                        }
                    })
                );
            }
        }
    }
}

customElements.define("lsmb-checkbox", LsmbCheckBox);
