/** @format */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";

const dojoCheckBox = require("dijit/form/CheckBox");
const on = require("dojo/on");
const topic = require("dojo/topic");

export class LsmbCheckBox extends LsmbBaseInput {
    _valueAttrs() {
        return [...super._valueAttrs(), "checked", "topic", "update-from"];
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
            let widget = this.dojoWidget;
            let props = this._collectProps();
            if (props.topic) {
                widget.own(
                    on(widget.domNode, "change", () => {
                        if (widget.checked) {
                            topic.publish(props.topic, props.value);
                        } else {
                            topic.publish(props.topic, null);
                        }
                    })
                );
            }
            if (props["update-from"]) {
                props["update-from"].split(",").forEach((channel) => {
                    widget.own(
                        topic.subscribe(channel, (value) => {
                            widget.set("checked", value);
                        })
                    );
                });
            }
        }
    }
}

customElements.define("lsmb-checkbox", LsmbCheckBox);
