/** @format */

import { createTestingPinia } from "@pinia/testing";

// import any store you want to interact with in tests
import { useLanguagesStore } from "@/store/languages";

const pinia = createTestingPinia({ stubActions: false });

let languages;
beforeEach(() => {
    languages = useLanguagesStore(pinia);
});

describe("Language Store", () => {
    it("initialize", async () => {
        await languages.initialize();
        expect(languages.fields).toStrictEqual(["_meta", "code", "default", "description"]);
        expect(languages.items).toStrictEqual([
            { code: "en", default: false, description: "English" },
            { code: "fr", default: false, description: "Français" }
        ]);
        expect(languages._links).toStrictEqual([{
            title : "HTML",
            rel : "download",
            href : "?format=HTML"
        }]);
    });

    it("get English languages en", async () => {
        await languages.initialize();
        const language = await languages.get("en");
        expect(language).toStrictEqual({
            _meta: { ETag: "1234567890" },
            code: "en",
            description: "English"
        });
    });

    it("save English american language en", async () => {
        await languages.initialize();
        await languages.get("en");
        await languages.save("en", { code: "en", description: "English (american)" });
        expect(languages.items).toStrictEqual([
            { code: "en", default: false, description: "English (american)" },
            { code: "fr", default: false, description: "Français" }
        ]);
    });

    it("get Invalid language zz", async () => {
        await languages.initialize();
        await expect(async () => {await languages.get("zz")}).rejects.toThrow("HTTP Error: 404");
    });

    it("add Mayan language my", async () => {
        await languages.initialize();
        await languages.add({ code: "my", description: "Mayan" });
        expect(languages.items[languages.items.length-1]).toStrictEqual({
            _meta: { ETag: "1234567891" },
            code: "my",
            description: "Mayan"
        });
    });
});
