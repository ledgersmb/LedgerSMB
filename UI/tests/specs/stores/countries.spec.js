/** @format */
/* eslint-disable no-console */

import { createTestingPinia } from "@pinia/testing";

// import any store you want to interact with in tests
import { useCountriesStore } from "@/store/countries";

const pinia = createTestingPinia({ stubActions: false });

let countries;
beforeEach(() => {
    countries = useCountriesStore(pinia);
});

describe("Country Store", () => {
    it("initialize", async () => {
        await countries.initialize();
        expect(countries.fields).toStrictEqual(["_meta", "code", "default", "name"]);
        expect(countries.items).toStrictEqual([
            { code: "ca", default: false, name: "Canada" },
            { code: "us", default: false, name: "United States" }
        ]);
        expect(countries._links).toStrictEqual([{
            title : "HTML",
            rel : "download",
            href : "?format=HTML"
        }]);
    });

    it("get United States country us", async () => {
        await countries.initialize();
        const country = await countries.get("us");
        expect(country).toStrictEqual({
            _meta: { ETag: "1234567890" },
            code: "us",
            name: "United States"
        });
    });

    it("save America country us", async () => {
        await countries.initialize();
        await countries.get("us");
        await countries.save("us", { code: "us", name: "America" });
        expect(countries.items).toStrictEqual([
            { code: "ca", default: false, name: "Canada" },
            { code: "us", default: false, name: "America" }
        ]);
    });

    it("get Invalid country zz", async () => {
        await countries.initialize();
        await expect(async () => {await countries.get("zz")}).rejects.toThrow("HTTP Error: 404");
    });

    it("add Atlantida country zz", async () => {
        await countries.initialize();
        await countries.add({ code: "zz", name: "Atlantida" });
        expect(countries.items[countries.items.length-1]).toStrictEqual({
            _meta: { ETag: "1234567891" },
            code: "zz",
            name: "Atlantida"
        });
    });
});
