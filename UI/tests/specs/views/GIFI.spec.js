/* @format */
/* global retry */

import GIFI from "@/views/GIFI.vue";
import { useSessionUserStore } from "@/store/sessionUser";
import { factory } from "./factory";

let wrapper;
let sessionUser;

describe("GIFI - register as a component", () => {
    beforeEach(() => {
        wrapper = factory(GIFI);
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

        const gifi_items = wrapper.findAll(".data-row");
        expect(gifi_items).toHaveLength(2);

        // Validate data displayed
        let data = gifi_items.map((rows) => {
            return rows.findAll(".input-box").map((row) => row.element.value);
        });
        expect(data).toEqual([
            ["0000", "Dummy account"],
            ["0001", "Dummy account 1"]
        ]);

        // TODO: Test links
        // expect that the links displayed match
        // what was returned by the API
    });

    it("should show dialog with editable data", async () => {
        // Give user edition capability
        sessionUser.$patch({ roles: ["gifi_edit"] });

        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() =>
            expect(wrapper.find(".dynatableData").isVisible()).toBe(true)
        );

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const gifi_items = wrapper.findAll(".data-row");
        expect(gifi_items).toHaveLength(2);

        // Validate data displayed
        let data = gifi_items.map((rows) => {
            return rows.findAll(".input-box").map((row) => row.element.value);
        });
        expect(data).toEqual([
            ["0000", "Dummy account"],
            ["0001", "Dummy account 1"]
        ]);

        // Validate the buttons
        const buttons = gifi_items.map((rows) => {
            return rows.findAll("button").map((row) => row.element.name);
        });
        expect(buttons).toEqual([
            ["modify", "save", "cancel"],
            ["modify", "save", "cancel"]
        ]);
    });

    it("should make GIFI codes immutable after creation", async () => {
        sessionUser.$patch({ roles: ["gifi_create", "gifi_edit"] });

        await retry(() =>
            expect(wrapper.find(".dynatableData").isVisible()).toBe(true)
        );

        const existingRow = wrapper.findAll(".dynatableData .data-row").at(0);
        const existingCode = existingRow.get('[name="accno"]');
        const existingDescription = existingRow.get('[name="description"]');

        await existingRow.get('[name="modify"]').trigger("click");
        await retry(() =>
            expect(existingDescription.element.readOnly).toBe(false)
        );

        expect(existingCode.element.readOnly).toBe(true);

        const newCode = wrapper.get('tfoot [name="accno"]');
        expect(newCode.element.readOnly).toBe(false);
    });
});
