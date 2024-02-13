/** @format */

import { createTestingPinia } from "@pinia/testing";

// import any store you want to interact with in tests
import { useWarehousesStore } from "@/store/warehouses";

const pinia = createTestingPinia({ stubActions: false });

let warehouses;
beforeEach(() => {
    warehouses = useWarehousesStore(pinia);
});

describe("Warehouses Store", () => {
    it("initialize", async () => {
        await warehouses.initialize();
        expect(warehouses.fields).toStrictEqual(["id", "description"]);
        expect(warehouses.items).toStrictEqual([
            { id: "1", description: "Modern warehouse", _meta: { ETag: "1234567892" } },
            { id: "2", description: "Huge warehouse", _meta: { ETag: "1234567890" } },
            { id: "3", description: "Moon warehouse", _meta: { ETag: "1234567893" } }
        ]);
        expect(warehouses._links).toStrictEqual([{
            title : "HTML",
            rel : "download",
            href : "?format=HTML"
        }]);
    });

    it("get warehouse #2", async () => {
        await warehouses.initialize();
        const warehouse = await warehouses.get("2");
        expect(warehouse).toStrictEqual({
            _meta: { ETag: "1234567890" },
            id: "2",
            description: "Huge warehouse"
        });
    });

    it("update warehouse #2", async () => {
        await warehouses.initialize();
        await warehouses.get("2");
        await warehouses.save("2", { id: "2", description: "Biggest warehouse" });
        expect(warehouses.items).toStrictEqual([
            { id: "1", description: "Modern warehouse", _meta: { ETag: "1234567892" } },
            { id: "2", description: "Biggest warehouse", _meta: { ETag: "1234567891" } },
            { id: "3", description: "Moon warehouse", _meta: { ETag: "1234567893" } }
        ]);
    });

    it("get Invalid warehouse #4", async () => {
        await warehouses.initialize();
        await expect(async () => {await warehouses.get("4")}).rejects.toThrow("HTTP Error: 404");
    });

    it("add Mars warehouse", async () => {
        await warehouses.initialize();
        await warehouses.add({ id: "4", description: "Mars warehouse" });
        expect(warehouses.items[warehouses.items.length-1]).toStrictEqual({
            _meta: { ETag: "1234567891" },
            id: "4",
            description: "Mars warehouse"
        });
    });
});
