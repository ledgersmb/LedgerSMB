/** @format */

import { createTestingPinia } from "@pinia/testing";

// import any store you want to interact with in tests
import { useGIFIsStore } from "@/store/gifis";

const pinia = createTestingPinia({ stubActions: false });

let gifies;
beforeEach(() => {
    gifies = useGIFIsStore(pinia);
});

describe("GIFI Store", () => {
    it("initialize", async () => {
        await gifies.initialize();
        expect(gifies.fields).toMatchObject(["accno", "description"]);
        expect(await gifies.items).toMatchObject([
            {
                accno: "0000",
                description: "Dummy account",
                _meta: { ETag: "1234567890" }
            },
            {
                accno: "0001",
                description: "Dummy account 1",
                _meta: { ETag: "1234567889" }
            }
        ]);
    });

    it("get 0000", async () => {
        await gifies.initialize();
        const gifi = await gifies.get("0000");
        expect(gifi).toMatchObject({
            _meta: { ETag: "1234567890" },
            accno: "0000",
            description: "Dummy account"
        });
    });

    it("save Funny account 0000", async () => {
        await gifies.initialize();
        await gifies.get("0000");
        await gifies.save("0000", {
            accno: "0000",
            description: "Funny account"
        });
        expect(gifies.items).toMatchObject([
            {
                accno: "0000",
                description: "Funny account",
                _meta: { ETag: "1234567891" }
            },
            {
                accno: "0001",
                description: "Dummy account 1",
                _meta: { ETag: "1234567889" }
            }
        ]);
    });

    it("get Invalid GIFI 0002", async () => {
        await gifies.initialize();
        await expect(async () => {
            await gifies.get("0002");
        }).rejects.toThrow("HTTP Error: 404");
    });

    it("add Dummy account 0002", async () => {
        await gifies.initialize();
        await gifies.add({ accno: "0002", description: "Dummy account 2" });
        expect(gifies.items[gifies.items.length - 1]).toMatchObject({
            _meta: { ETag: "1234567891" },
            accno: "0002",
            description: "Dummy account 2"
        });
    });
});
