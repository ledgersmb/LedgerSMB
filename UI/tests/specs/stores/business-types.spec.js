/** @format */

import { createTestingPinia } from "@pinia/testing";

// import any store you want to interact with in tests
import { useBusinessTypesStore } from "@/store/business-types";

const pinia = createTestingPinia({ stubActions: false });

let businessTypes;
beforeEach(() => {
    businessTypes = useBusinessTypesStore(pinia);
});

describe("Business Types Store", () => {
    it("initialize", async () => {
        await businessTypes.initialize();
        expect(businessTypes.fields).toMatchObject([
            "id",
            "description",
            "discount"
        ]);
        expect(businessTypes.items).toMatchObject([
            {
                id: "1",
                description: "Big customer",
                discount: 0.05,
                _meta: { "ETag": "1234567890" }
            },
            {
                id: "2",
                description: "Bigger customer",
                discount: 0.15,
                _meta: { "ETag": "1234567890" }
            }
        ]);
        expect(businessTypes._links).toMatchObject([
            {
                title: "HTML",
                rel: "download",
                href: "?format=HTML"
            }
        ]);
    });

    it("get Business Type #2", async () => {
        await businessTypes.initialize();
        const businessType = await businessTypes.get("2");
        expect(businessType).toMatchObject({
            _meta: { ETag: "1234567890" },
            id: "2",
            description: "Bigger customer",
            discount: 0.15
        });
    });

    it("update Business Type #2", async () => {
        await businessTypes.initialize();
        await businessTypes.get("2");
        await businessTypes.save("2", {
            description: "Bigger customer",
            discount: 0.25
        });
        expect(businessTypes.items).toMatchObject([
            {
                id: "1",
                description: "Big customer",
                discount: 0.05,
                _meta: { "ETag": "1234567890" }
            },
            {
                id: "2",
                description: "Bigger customer",
                discount: 0.25,
                _meta: { "ETag": "1234567891" }
            }
        ]);
    });

    it("get Invalid Business Type #3", async () => {
        await businessTypes.initialize();
        await expect(async () => {
            await businessTypes.get("3");
        }).rejects.toThrow("HTTP Error: 404");
    });

    it("add Business Type #3", async () => {
        await businessTypes.initialize();
        await businessTypes.add({
            id: "3",
            description: "Great customer",
            discount: 0.22
        });
        expect(
            businessTypes.items[businessTypes.items.length - 1]
        ).toMatchObject({
            _meta: { "ETag": "1234567891" },
            id: "3",
            description: "Great customer",
            discount: 0.22
        });
    });
});
