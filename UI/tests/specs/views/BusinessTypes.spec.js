/*
 * View tests
 *
 * @group views
 */
/* global retry */

import BusinessTypes from "@/views/BusinessTypes.vue";
import { useSessionUserStore } from "@/store/sessionUser";
import { factory } from "./factory";

let wrapper;
let sessionUser;

describe("BusinessTypes - register as a component", () => {
    
    beforeEach(() => {
        wrapper = factory(BusinessTypes);
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

        const businessType_items = wrapper.findAll('.data-row');
        expect(businessType_items).toHaveLength(2);

        // Validate data displayed
        let data = businessType_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
          [ "Big customer", "0.05"],
          [ "Bigger customer", "0.15"]
        ]);

        // TODO: Test links 
        // expect that the links displayed match
        // what was returned by the API
    });

  it("should show dialog with editable data", async () => {

        // Give user edition capability
        sessionUser.$patch({roles: ["business_type_edit"]});

        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const businessType_items = wrapper.findAll('.data-row');
        expect(businessType_items).toHaveLength(2);

        // Validate data displayed
        let data = businessType_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
          [ "Big customer", "0.05"],
          [ "Bigger customer", "0.15"]
        ]);

        // Validate the buttons
        const buttons = businessType_items.map((rows) => {
            return rows.findAll('button').map(row => row.element.name)
        });
        expect(buttons).toEqual([
          [ 'modify', 'save', 'cancel' ],
          [ 'modify', 'save', 'cancel' ]
        ]);
    });
});
