/** @format */

import { LsmbBaseInput } from "@/elements/lsmb-base-input";
import { useCountriesStore } from "@/store/countries";

const Select = require("dijit/form/Select");
const registry = require("dijit/registry");

export class LsmbCountry extends LsmbBaseInput {
    store = null;

    widgetWrapper = null;

    _boolAttrs() {
        return ["default_blank"];
    }

    _widgetRoot() {
        if (this.widgetWrapper) {
            return this.widgetWrapper;
        }
        this.widgetWrapper = document.createElement("span");
        this.appendChild(this.widgetWrapper);

        return this.widgetWrapper;
    }

    async connectedCallback() {
        let props = this._collectProps();

        if (!this.store) {
            /* Instantiate *and* initialize store before assigning to
             * the object property to avoid a race condition.
             */
            const store = useCountriesStore();
            await store.initialize();
            this.store = store;
        }

        const options = this.store.items.map((element) => {
            return { label: element.localizedName, value: element.code };
        });

        options.sort((a, b) => a.label.localeCompare(b.label));

        if ("default_blank" in props) {
            options.unshift({ label: "", value: "" });
        }

        this.dojoWidget = new Select({
            name: props.name,
            options: options
        });

        super.connectedCallback();
    }

    disconnectedCallback() {
        if (this.widgetWrapper) {
            this.widgetWrapper.remove();
            this.widgetWrapper = null;
        }

        if (this.dojoWidget) {
            registry.remove(this.dojoWidget.id);
            this.dojoWidget.destroy(false);
            this.dojoWidget = null;
        }

        super.disconnectedCallback();
    }
}

customElements.define("lsmb-country", LsmbCountry);
