/* global retry */

import Pricegroups from "@/views/Pricegroups.vue";
import { useSessionUserStore } from "@/store/sessionUser";
import { factory } from "./factory";

let wrapper;
let sessionUser;

describe("Pricegroups - register as a component", () => {

    beforeEach(() => {
        wrapper = factory(Pricegroups);
        sessionUser = useSessionUserStore();
    });
    afterEach(() => {
        // wrapper.unmount();
    });

    it("should show dialog", async () => {
        wrapper = factory(Pricegroups);
        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const pricegroup_items = wrapper.findAll('.data-row');
        expect(pricegroup_items).toHaveLength(2);

        // Validate data displayed
        let data = pricegroup_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
          [ "Price group 1" ],
          [ "Price group 2" ]
      ]);

        // TODO: Test links
        // expect that the links displayed match
        // what was returned by the API
    });

    it("should show dialog with editable data", async () => {

        // Give user edition capability
        sessionUser.$patch({roles: ["pricegroup_edit"]});

        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const pricegroup_items = wrapper.findAll('.data-row');
        expect(pricegroup_items).toHaveLength(2);

        // Validate data displayed
        let data = pricegroup_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
          [ "Price group 1" ],
          [ "Price group 2" ]
        ]);

        // Validate the buttons
        const buttons = pricegroup_items.map((rows) => {
            return rows.findAll('button').map(row => row.element.name)
        });
        expect(buttons).toEqual([
          [ 'modify', 'save', 'cancel' ],
          [ 'modify', 'save', 'cancel' ]
        ]);
    });
});
