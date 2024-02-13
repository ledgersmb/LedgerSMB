/* global retry */

import Countries from "@/views/Countries.vue";
import { useSessionUserStore } from "@/store/sessionUser";
import { factory } from "./factory";

let wrapper;
let sessionUser;

describe("Countries - register as a component", () => {

    beforeEach(() => {
        wrapper = factory(Countries);
        sessionUser = useSessionUserStore();
    });

    it("should show dialog", async () => {

        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const country_items = wrapper.findAll('.data-row');
        expect(country_items).toHaveLength(2);

        // Validate data displayed
        let data = country_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
            ["ca", "Canada"],
            ["us", "United States"]
        ]);

        // TODO: Test links
        // expect that the links displayed match
        // what was returned by the API
    });

    it("should show dialog with editable data", async () => {

        // Give user edition capability
        sessionUser.$patch({roles: ["country_edit"]});

        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        const country_items = wrapper.findAll('.data-row');
        expect(country_items).toHaveLength(2);

        // Validate data displayed
        let data = country_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
            ["ca", "Canada"],
            ["us", "United States"]
        ]);

        const defaults = country_items.map((rows) => {
            return rows.findAll('input[name="default"]').map(row => row.element.checked).at(0)
        });
        expect(defaults).toEqual([
            false, false
        ]);

        // Validate the buttons
        const buttons = country_items.map((rows) => {
            return rows.findAll('button').map(row => row.element.name)
        });
        expect(buttons).toEqual([
            [ 'change-default', 'modify', 'save', 'cancel' ],
            [ 'change-default', 'modify', 'save', 'cancel' ]
        ]);
    });

    it("should allow setting a default country", async () => {

        // Give user edition capability
        sessionUser.$patch({roles: ["country_edit"]});

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        let country_items = wrapper.findAll('.data-row');

        let defaults = country_items.map((rows) => {
            return rows.findAll('input[name="default"]').map(row => row.element.checked).at(0)
        });

        // No country selected
        expect(defaults).toEqual([
            false, false
        ]);

        // Validate the buttons
        const buttons = country_items.map((rows) => {
            return rows.find("button[name='change-default']");
        });
        // Set the default
        await buttons[0].trigger('click');
        await retry(() => expect(buttons[0].isVisible()).toBe(false));

        country_items = wrapper.findAll('.data-row');

        expect(country_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        })).toEqual([
            ["ca", "Canada"],
            ["us", "United States"]
        ]);
        defaults = country_items.map((rows) => {
            return rows.findAll('input[name="default"]').map(row => row.element.checked).at(0)
        });
        expect(defaults).toEqual([
            true, false
        ]);

    });
});
