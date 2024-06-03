/** @format */
/* eslint-disable vue/component-definition-name-casing */
/* eslint-disable vue/require-prop-types, vue/one-component-per-file */

import { config } from "@vue/test-utils";
import { defineComponent } from "vue";

const lsmbText = defineComponent({
    name: "lsmb-text",
    props: [
        "autocomplete",
        "id",
        "label",
        "name",
        "required",
        "size",
        "tabindex",
        "type",
        "value"
    ],
    computed: {
        widgetid() {
            return "widgetid_" + this.id;
        }
    },
    template: `
    <div>
      <label :for=id>{{ id }}</label>
      <input :type=type :id=id :widgetid=widgetid :name=name :size=size
            :tabindex=tabindex :autocomplete=autocomplete
            :value=value :required=required>
    </div>
  `
});

const lsmbPassword = defineComponent({
    name: "lsmb-password",
    props: [
        "autocomplete",
        "id",
        "label",
        "name",
        "required",
        "size",
        "tabindex",
        "type",
        "value"
    ],
    computed: {
        widgetid() {
            return "widgetid_" + this.id;
        }
    },
    template: `
    <div>
      <label :for=id>{{ id }}</label>
      <input :type=type :id=id :widgetid=widgetid :name=name :size=size
              :tabindex=tabindex :autocomplete=autocomplete
              :value=value :required=required>
    </div>
`
});

const lsmbButton = defineComponent({
    name: "lsmb-button",
    props: ["id", "value", "disabled", "type", "name"],
    template: `
    <button :id=id :value=value :name=name :type=type
            :disabled=disabled>
      <slot />
    </button>
  `
});

const lsmbDate = defineComponent({
    name: "lsmb-date",
    props: ["id", "title", "name", "size", "required"],
    template: `
    <div>
      <label>{{ title }}</label>
      <span :id=id :name=name :size=size :required=required</span>
    </div>
  `
});

const lsmbFile = defineComponent({
    name: "lsmb-file",
    props: ["id", "label", "accept", "disabled", "name", "required"],
    template: `
    <div>
      <label>{{ label }}</label>
      <span>
        <input type=file :id=id :name=name :accept=accept
               :required=required>
      </span>
    </div>
  `
});

config.global.stubs = {
    lsmbButton,
    lsmbPassword,
    lsmbText,
    lsmbDate,
    lsmbFile
};
