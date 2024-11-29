/** @format */

import { createTestingPinia } from "@pinia/testing";

// import any store you want to interact with in tests
import { usePricegroupsStore } from "@/store/pricegroups";

const pinia = createTestingPinia({ stubActions: false });

let pricegroups;
beforeEach(() => {
    pricegroups = usePricegroupsStore(pinia);
});

describe("Pricegroup Store", () => {
    it("initialize", async () => {
        await pricegroups.initialize();
        expect(pricegroups.fields).toMatchObject(["id", "description"]);
        expect(pricegroups.items).toMatchObject([
            {
                id: "1",
                description: "Price group 1",
                _meta: { ETag: "1234567890" }
            },
            {
                id: "2",
                description: "Price group 2",
                _meta: { ETag: "1234567889" }
            }
        ]);
        expect(pricegroups._links).toMatchObject([
            {
                title: "HTML",
                rel: "download",
                href: "?format=HTML"
            }
        ]);
    });

    it("get Price Group 1", async () => {
        await pricegroups.initialize();
        const pricegroup = await pricegroups.get("1");
        expect(pricegroup).toMatchObject({
            _meta: { ETag: "1234567890" },
            id: "1",
            description: "Price group 1"
        });
    });

    it("save Price Group 1", async () => {
        await pricegroups.initialize();
        await pricegroups.get("1");
        await pricegroups.save("1", { id: "1", description: "Price Group #1" });
        expect(pricegroups.items).toMatchObject([
            {
                id: "1",
                description: "Price Group #1",
                _meta: { ETag: "1234567891" }
            },
            {
                id: "2",
                description: "Price group 2",
                _meta: { ETag: "1234567889" }
            }
        ]);
    });

    it("get Invalid Price Group 3", async () => {
        await pricegroups.initialize();
        await expect(async () => {
            await pricegroups.get("3");
        }).rejects.toThrow("HTTP Error: 404");
    });

    it("add Price Group 3", async () => {
        await pricegroups.initialize();
        await pricegroups.add({ id: "3", description: "Price Group #3" });
        expect(pricegroups.items[pricegroups.items.length - 1]).toMatchObject({
            _meta: { ETag: "1234567891" },
            id: "3",
            description: "Price Group #3"
        });
    });
});
