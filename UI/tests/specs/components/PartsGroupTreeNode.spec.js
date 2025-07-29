/** @format */

import { describe, expect, it } from "@jest/globals";
import { mount } from "@vue/test-utils";
import { Quasar } from "quasar";

import PartsGroupTreeNode from "@/components/PartsGroupTreeNode";

describe("PartsGroupTreeNode", () => {
    it("renders a node without children", () => {
        const wrapper = mount(PartsGroupTreeNode, {
            global: {
                plugins: [Quasar]
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
