/* global retry */

import SIC from "@/views/SIC.vue";
import { useSessionUserStore } from "@/store/sessionUser";
import { factory } from "./factory";

let wrapper;
let sessionUser;

describe("SIC - register as a component", () => {

    beforeEach(() => {
        wrapper = factory(SIC);
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

        const sic_items = wrapper.findAll('.data-row');
        expect(sic_items).toHaveLength(2);

        // Validate data displayed
        let data = sic_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
          [ "541330", "Engineering service" ],
          [ "611430", "Professional and management development training" ]
        ]);

        // TODO: Test links
        // expect that the links displayed match
        // what was returned by the API
    });

    it("should show dialog with editable data", async () => {

        // Give user edition capability
        sessionUser.$patch({roles: ["sic_edit"]});

        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const sic_items = wrapper.findAll('.data-row');
        expect(sic_items).toHaveLength(2);

        // Validate data displayed
        let data = sic_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
          [ "541330", "Engineering service" ],
          [ "611430", "Professional and management development training" ]
        ]);

        // Validate the buttons
        const buttons = sic_items.map((rows) => {
            return rows.findAll('button').map(row => row.element.name)
        });
        expect(buttons).toEqual([
          [ 'modify', 'save', 'cancel' ],
          [ 'modify', 'save', 'cancel' ]
        ]);
    });
});
