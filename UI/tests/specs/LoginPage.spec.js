/** @format */
/* global retry */

/*
 * View tests
 *
 * @group view
 */

import { mount } from "@vue/test-utils";

import LoginPage from "@/views/LoginPage.vue";

let wrapper;
const successFn = jest.fn();

describe("LoginPage", () => {
    it("should show dialog", () => {
        wrapper = mount(LoginPage);
        expect(wrapper.find("h1.login").text()).toMatch(/[\d.](-dev)?/);

        expect(wrapper.get("#username").element.value).toBe("");
        expect(wrapper.get("#password").element.value).toBe("");
        expect(wrapper.get("#company").element.value).toBe("");

        const loginButton = wrapper.get("#login");

        expect(loginButton.text()).toBe("Login");
        expect(loginButton.isDisabled()).toBe(true);
    });

    it("should enable login button when filled", async () => {
        wrapper = mount(LoginPage);

        const loginButton = wrapper.get("#login");
        expect(await loginButton.isDisabled()).toBe(true);

        wrapper.find("#username").setValue("MyUser");
        expect(await loginButton.isDisabled()).toBe(true);

        wrapper.find("#password").setValue("MyPassword");
        expect(await loginButton.isDisabled()).toBe(false);

        wrapper.find("#company").setValue("MyCompany");
        expect(await loginButton.isDisabled()).toBe(false);
    });

    it("should fail on bad user", async () => {
        const jsdomAlert = window.alert; // remember the jsdom alert
        window.alert = jest.fn(); // provide an empty implementation for window.alert

        wrapper = mount(LoginPage);

        wrapper.find("#username").setValue("BadUser");
        expect(await wrapper.get("#login").isDisabled()).toBe(true);

        wrapper.find("#password").setValue("MyPassword");
        expect(await wrapper.get("#login").isDisabled()).toBe(false);

        wrapper.find("#company").setValue("MyCompany");
        expect(await wrapper.get("#login").isDisabled()).toBe(false);

        await wrapper.get("#login").trigger("click");

        await retry(() => expect(wrapper.get("#errorText").text()).toBe(
            "Access denied: Bad username or password"
        ));
        window.alert = jsdomAlert; // restore the jsdom alert
    });

    it("should fail on bad version", async () => {
        const jsdomAlert = window.alert; // remember the jsdom alert
        window.alert = jest.fn(); // provide an empty implementation for window.alert

        wrapper = mount(LoginPage);

        await wrapper.find("#username").setValue("MyUser");
        await wrapper.find("#password").setValue("MyPassword");
        await wrapper.find("#company").setValue("MyOldCompany");

        await wrapper.get("#login").trigger("click");

        await retry (() => expect(wrapper.get("#errorText").text()).toBe(
            "Database version mismatch"
        ));
        window.alert = jsdomAlert; // restore the jsdom alert
    });

    it("should fail unknown error", async () => {
        const jsdomAlert = window.alert; // remember the jsdom alert
        window.alert = jest.fn(); // provide an empty implementation for window.alert

        wrapper = mount(LoginPage);

        await wrapper.find("#username").setValue("My");
        await wrapper.find("#password").setValue("My");
        await wrapper.find("#company").setValue("My");

        await wrapper.get("#login").trigger("click");

        await retry(() => expect(window.alert).toHaveBeenCalledTimes(1));
        expect(window.alert).toHaveBeenCalledWith(
          "Unknown error preventing login",
        );
        window.alert = jsdomAlert; // restore the jsdom alert
    });

    it("should login when filled", async () => {
        wrapper = mount(LoginPage, {
            propsData: {
                successFn
            }
        });

        await wrapper.find("#username").setValue("MyUser");
        await wrapper.find("#password").setValue("MyPassword");
        await wrapper.find("#company").setValue("MyCompany");

        await wrapper.get("#login").trigger("click");

        expect(wrapper.get(".v-enter-active").text())
            .toBe("Logging in... Please wait.");

        await retry(() => expect(successFn).toHaveBeenCalledTimes(1));
        expect(successFn).toHaveBeenCalledWith({
            target: "erp.pl?action=root"
        });
    });
});
