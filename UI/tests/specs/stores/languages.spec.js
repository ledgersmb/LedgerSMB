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
        expect(languages.fields).toMatchObject([
            "_meta",
            "code",
            "default",
            "description"
        ]);
        expect(languages.items).toMatchObject([
            {
                code: "en",
                default: false,
                description: "English",
                _meta: { ETag: "1234567890" }
            },
            {
                code: "fr",
                default: false,
                description: "Français",
                _meta: { ETag: "2345678901" }
            }
        ]);
        expect(languages._links).toMatchObject([
            {
                title: "HTML",
                rel: "download",
                href: "?format=HTML"
            }
        ]);
    });

    it("get English languages en", async () => {
        await languages.initialize();
        const language = await languages.get("en");
        expect(language).toMatchObject({
            _meta: { ETag: "1234567890" },
            code: "en",
            default: false,
            description: "English"
        });
    });

    it("save English american language en", async () => {
        await languages.initialize();
        await languages.get("en");
        await languages.save("en", {
            code: "en",
            description: "English (american)"
        });
        expect(languages.items).toMatchObject([
            {
                code: "en",
                default: false,
                description: "English (american)",
                _meta: { ETag: "1234567891" }
            },
            {
                code: "fr",
                default: false,
                description: "Français",
                _meta: { ETag: "2345678901" }
            }
        ]);
    });

    it("get Invalid language zz", async () => {
        await languages.initialize();
        await expect(async () => {
            await languages.get("zz");
        }).rejects.toThrow("HTTP Error: 404");
    });

    it("add Mayan language my", async () => {
        await languages.initialize();
        await languages.add({ code: "my", description: "Mayan" });
        expect(languages.items[languages.items.length - 1]).toMatchObject({
            _meta: { ETag: "1234567891" },
            code: "my",
            description: "Mayan"
        });
    });
});
