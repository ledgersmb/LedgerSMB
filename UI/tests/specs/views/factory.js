/** @format */

import { mount } from "@vue/test-utils";
import { createPinia } from "pinia";

import { createToasterMachine } from "@/components/Toaster.machines";

const toasterMachine = createToasterMachine({ items: [] }, {});
const { send } = toasterMachine;

function factory(view) {
    const wrapper = mount(view, {
        global: {
            plugins: [
                // create a fresh Pinia instance and make it active so it's automatically picked
                // up by any useStore() call without having to pass it to it:
                // `useStore(pinia)`
                createPinia()
            ],
            provide: {
                "toaster-machine": toasterMachine,
                notify(notification) {
                    send({ type: "add", item: notification });
                }
            }
        }
    });
    return wrapper;
}

export { factory };
