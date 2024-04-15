/** @format */
/* global retry */

import Warehouses from "@/views/Warehouses.vue";
import { useSessionUserStore } from "@/store/sessionUser";
import { factory } from "./factory";

let wrapper;
let sessionUser;

describe("Warehouses - register as a component", () => {
    beforeEach(() => {
        wrapper = factory(Warehouses);
        sessionUser = useSessionUserStore();
    });
    afterEach(() => {
        // wrapper.unmount();
    });

    it("should show dialog", async () => {
        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() =>
            expect(wrapper.find(".dynatableData").isVisible()).toBe(true)
        );

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const warehouse_items = wrapper.findAll(".data-row");
        expect(warehouse_items).toHaveLength(3);

        // Validate data displayed
        let data = warehouse_items.map((rows) => {
            return rows.findAll(".input-box").map((row) => row.element.value);
        });
        expect(data).toEqual([
            ["Modern warehouse"],
            ["Huge warehouse"],
            ["Moon warehouse"]
        ]);

        // TODO: Test links
        // expect that the links displayed match
        // what was returned by the API
    });

    it("should show dialog with editable data", async () => {
        // Give user edition capability
        sessionUser.$patch({ roles: ["warehouse_edit"] });

        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() =>
            expect(wrapper.find(".dynatableData").isVisible()).toBe(true)
        );

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const warehouse_items = wrapper.findAll(".data-row");
        expect(warehouse_items).toHaveLength(3);

        // Validate data displayed
        let data = warehouse_items.map((rows) => {
            return rows.findAll(".input-box").map((row) => row.element.value);
        });
        expect(data).toEqual([
            ["Modern warehouse"],
            ["Huge warehouse"],
            ["Moon warehouse"]
        ]);

        // Validate the buttons
        const buttons = warehouse_items.map((rows) => {
            return rows.findAll("button").map((row) => row.element.name);
        });
        expect(buttons).toEqual([
            ["modify", "save", "cancel"],
            ["modify", "save", "cancel"],
            ["modify", "save", "cancel"]
        ]);
    });
});
