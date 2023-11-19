/* global retry */

import Languages from "@/views/Languages.vue";
import { useSessionUserStore } from "@/store/sessionUser";
import { factory } from "./factory";

let wrapper;
let sessionUser;

describe("Languages", () => {

    beforeEach(() => {
        wrapper = factory(Languages);
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

        const language_items = wrapper.findAll('.data-row');
        expect(language_items).toHaveLength(2);

        // Validate data displayed
        let data = language_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
            ["en", "English"],
            ["fr", "Français"]
        ]);

        // TODO: Test links
        // expect that the links displayed match
        // what was returned by the API
    });

    it("should show dialog with editable data", async () => {

        // Give user edition capability
        sessionUser.$patch({roles: ["language_edit"]});

        expect(wrapper.exists()).toBeTruthy();

        // Check loading
        expect(wrapper.get(".dynatableLoading").text()).toBe("Loading...");

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        // Validate against snapshot
        expect(wrapper.element).toMatchSnapshot();

        const language_items = wrapper.findAll('.data-row');
        expect(language_items).toHaveLength(2);

        // Validate data displayed
        let data = language_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
            ["en", "English"],
            ["fr", "Français"]
        ]);

        // Validate the buttons
        const buttons = language_items.map((rows) => {
            return rows.findAll('button').map(row => row.element.name)
        });
        expect(buttons).toEqual([
            [ 'change-default', 'modify', 'save', 'cancel' ],
            [ 'change-default', 'modify', 'save', 'cancel' ]
        ]);
  });

    it("should edit a language and save data", async () => {

        // Give user edition capability
        sessionUser.$patch({roles: ["language_edit"]});

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        // Find 1st item
        const language_item = wrapper.findAll('.data-row').at(0);
        const code = language_item.find('[name="code"]');
        const description = language_item.find('[name="description"]');
        const modify = language_item.find('[name="modify"]');
        const save = language_item.find('[name="save"]');
        const cancel = language_item.find('[name="cancel"]');

        // Validate
        expect(code.element.value).toBe("en");
        expect(description.element.value).toBe("English");
        expect(modify.element.disabled).toBe(false);
        expect(save.element.disabled).toBe(true);
        expect(cancel.element.disabled).toBe(true);

        await modify.trigger('click');

        // Proper buttons enabled?
        await retry(() => expect(modify.element.disabled).toBe(true));
        expect(save.element.disabled).toBe(false);
        expect(cancel.element.disabled).toBe(false);

        description.setValue("English (american)");
        await save.trigger('click');
        await retry(() => expect(modify.element.disabled).toBe(false));

        expect(wrapper.findAll('.data-row').map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        })).toEqual([
            ["en", "English (american)"],
            ["fr", "Français"]
        ]);
        expect(modify.element.disabled).toBe(false);
        expect(save.element.disabled).toBe(true);
        expect(cancel.element.disabled).toBe(true);
    });

    it("should allow adding a new language and save data", async () => {

        // Give user edition capability
        sessionUser.$patch({roles: ["language_create", "language_edit"]});

        // Wait until loading done
        await retry(() => expect(wrapper.find(".dynatableData").isVisible()).toBe(true));

        let language_items = wrapper.findAll('.data-row');
        expect(language_items).toHaveLength(3);

        // Validate data displayed
        let data = language_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
            ["en", "English"],
            ["fr", "Français"],
            ["", ""]
        ]);

        // Find 3rd item
        let language_item = wrapper.findAll('.data-row').at(2);
        let code = language_item.find('[name="code"]');
        let description = language_item.find('[name="description"]');
        let add = language_item.find('[name="add"]');
        let modify = language_item.find('[name="modify"]');
        let save = language_item.find('[name="save"]');
        let cancel = language_item.find('[name="cancel"]');

        // Validate
        expect(code.element.value).toBe("");
        expect(description.element.value).toBe("");
        expect(add.element.disabled).toBe(false);
        expect(modify.exists()).toBe(false);
        expect(save.exists()).toBe(false);
        expect(cancel.exists()).toBe(false);

        // Add new entry
        code.setValue("my");
        description.setValue("Mayan");
        await add.trigger('click');

        // Proper buttons enabled?
        await retry(() => expect(wrapper.findAll('.data-row')).toHaveLength(4));

        language_items = wrapper.findAll('.data-row');

        // Validate data displayed
        data = language_items.map((rows) => {
            return rows.findAll('.input-box').map(row => row.element.value)
        });
        expect(data).toEqual([
            ["en", "English"],
            ["fr", "Français"],
            ["my", "Mayan"],
            ["", ""]
        ]);
    });

});
