/** @format */

import { describe, expect, it } from "@jest/globals";
import { installQuasarPlugin, qLayoutInjections } from '@quasar/quasar-app-extension-testing-unit-jest';
import { mount } from "@vue/test-utils";

import PartsGroupTreeNode from "@/components/PartsGroupTreeNode";

installQuasarPlugin();



describe("PartsGroupTreeNode", () => {
    it("renders a node without children", () => {
      const wrapper = mount(PartsGroupTreeNode, {
        global: { provide: qLayoutInjections() },
            props: {
                node: {
                    description: "Description text",
                    children: []
                }
            }
        });

        const label = wrapper.find(".q-item__label");
        expect(label.text()).toBe("Description text");
    });
});
