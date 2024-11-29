/** @format */

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
        expect(countries.fields).toMatchObject([
            "_meta",
            "code",
            "default",
            "name"
        ]);
        expect(countries.items).toMatchObject([
            {
                code: "ca",
                default: false,
                name: "Canada",
                _meta: { ETag: "2345678901" }
            },
            {
                code: "us",
                default: false,
                name: "United States",
                _meta: { ETag: "1234567890" }
            }
        ]);
        expect(countries._links).toMatchObject([
            {
                title: "HTML",
                rel: "download",
                href: "?format=HTML"
            }
        ]);
    });

    it("get United States country us", async () => {
        await countries.initialize();
        const country = await countries.get("us");
        expect(country).toMatchObject({
            _meta: { ETag: "1234567890" },
            code: "us",
            default: false,
            name: "United States"
        });
    });

    it("save America country us", async () => {
        await countries.initialize();
        await countries.get("us");
        await countries.save("us", { code: "us", name: "America" });
        expect(countries.items).toMatchObject([
            {
                code: "ca",
                default: false,
                name: "Canada",
                _meta: { ETag: "2345678901" }
            },
            {
                code: "us",
                default: false,
                name: "America",
                _meta: { ETag: "1234567891" }
            }
        ]);
    });

    it("get Invalid country zz", async () => {
        await countries.initialize();
        await expect(async () => {
            await countries.get("zz");
        }).rejects.toThrow("HTTP Error: 404");
    });

    it("add Atlantida country zz", async () => {
        await countries.initialize();
        await countries.add({ code: "zz", name: "Atlantida" });
        expect(countries.items[countries.items.length - 1]).toMatchObject({
            _meta: { ETag: "1234567891" },
            code: "zz",
            name: "Atlantida"
        });
    });
});
