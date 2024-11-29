/** @format */

import { createTestingPinia } from "@pinia/testing";

// import any store you want to interact with in tests
import { useSICsStore } from "@/store/sics";

const pinia = createTestingPinia({ stubActions: false });

let sics;
beforeEach(() => {
    sics = useSICsStore(pinia);
});

describe("Sic Store", () => {
    it("initialize", async () => {
        await sics.initialize();
        expect(sics.fields).toMatchObject(["code", "sictype", "description"]);
        expect(sics.items).toMatchObject([
            {
                code: "541330",
                description: "Engineering service",
                _meta: { ETag: "1234567890" }
            },
            {
                code: "611430",
                description: "Professional and management development training",
                _meta: { ETag: "1234567889" }
            }
        ]);
        expect(sics._links).toMatchObject([
            {
                title: "HTML",
                rel: "download",
                href: "?format=HTML"
            }
        ]);
    });

    it("get Computer systems integrators sics 541330", async () => {
        await sics.initialize();
        const sic = await sics.get("541330");
        expect(sic).toMatchObject({
            _meta: { ETag: "1234567890" },
            code: "541330",
            description: "Engineering service"
        });
    });

    it("save Computer Systems Design and Related Services sic 541330", async () => {
        await sics.initialize();
        await sics.get("541330");
        await sics.save("541330", {
            code: "541330",
            description: "Engineering services"
        });
        expect(sics.items).toMatchObject([
            {
                code: "541330",
                description: "Engineering services",
                _meta: { ETag: "1234567891" }
            },
            {
                code: "611430",
                description: "Professional and management development training",
                _meta: { ETag: "1234567889" }
            }
        ]);
    });

    it("get Invalid sic 541510", async () => {
        await sics.initialize();
        await expect(async () => {
            await sics.get("541510");
        }).rejects.toThrow("HTTP Error: 404");
    });

    it("add Design of computer systems sic 541510", async () => {
        await sics.initialize();
        await sics.add({
            code: "541510",
            description: "Design of computer systems"
        });
        expect(sics.items[sics.items.length - 1]).toMatchObject({
            _meta: { ETag: "1234567891" },
            code: "541510",
            description: "Design of computer systems"
        });
    });
});
