/*
 * View tests
 *
 * @group views
 */
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
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const gifi_items = wrapper.findAll('.data-row');
        expect(gifi_items).toHaveLength(2);

        // Validate data displayed
        let data = gifi_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
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
        sessionUser.$patch({roles: ["gifi_edit"]});

        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const gifi_items = wrapper.findAll('.data-row');
        expect(gifi_items).toHaveLength(2);

        // Validate data displayed
        let data = gifi_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
            ["0000", "Dummy account"],
            ["0001", "Dummy account 1"]
        ]);

        // Validate the buttons
        const buttons = gifi_items.map((rows) => {
            return rows.findAll('button').map(row => row.element.name)
        });
        expect(buttons).toEqual([
            [ 'modify', 'save', 'cancel' ],
            [ 'modify', 'save', 'cancel' ]
        ]);
    });
});
