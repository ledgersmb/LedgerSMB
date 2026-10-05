/** @format */

import { describe, expect, it } from "@jest/globals";
import { mount } from "@vue/test-utils";

import PartsGroupTreeNode from "@/components/PartsGroupTreeNode";

const stubGeneric = {
    template: "<div><slot /></div>"
};
const stubLabel = {
    template: '<div class="q-item__label"><slot /></div>'
};

describe("PartsGroupTreeNode", () => {
    it("renders a node without children", () => {
        const wrapper = mount(PartsGroupTreeNode, {
            shallow: true,
            global: {
                stubs: {
                    QItem: stubGeneric,
                    QItemLabel: stubLabel,
                    QItemSection: stubGeneric
                }
            },
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
