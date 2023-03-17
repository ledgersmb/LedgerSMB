/** @format */
/* eslint-disable no-console */

/*
 * Store tests
 *
 * @group unit
 */

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
        expect(countries.fields).toStrictEqual(["short_name", "name"]);
        expect(countries.items).toStrictEqual([
            { short_name: "ca", name: "Canada" },
            { short_name: "us", name: "United States" }
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
            short_name: "us",
            name: "United States"
        });
    });

    it("save America country us", async () => {
        await countries.initialize();
        await countries.get("us");
        await countries.save("us", { short_name: "us", name: "America" });
        expect(countries.items).toStrictEqual([
            { short_name: "ca", name: "Canada" },
            { short_name: "us", name: "America" }
        ]);
    });

    it("get Invalid country zz", async () => {
        await countries.initialize();
        await expect(async () => {await countries.get("zz")}).rejects.toThrow("HTTP Error: 404");
    });

    it("add Atlantida country zz", async () => {
        await countries.initialize();
        await countries.add({ short_name: "zz", name: "Atlantida" });
        expect(countries.items[countries.items.length-1]).toStrictEqual({
            _meta: { ETag: "1234567891" },
            short_name: "zz",
            name: "Atlantida"
        });
    });
});
