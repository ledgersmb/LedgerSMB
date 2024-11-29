/** @format */

import { createTestingPinia } from "@pinia/testing";

// import any store you want to interact with in tests
import { useSessionUserStore } from "@/store/sessionUser";

const pinia = createTestingPinia({ stubActions: false });

let session;
beforeEach(() => {
    session = useSessionUserStore(pinia);
});

describe("Session Store", () => {
    it("initialize", async () => {
        await session.initialize();
        // expect(session.password_expiration).toBe("P1Y");
        expect(session.roles).toMatchObject([
            "account_all",
            "base_user",
            "cash_all",
            "gl_all"
        ]);
        expect(session.preferences).toMatchObject({
            numberformat: "1000.00",
            printer: null,
            stylesheet: "ledgersmb.css",
            dateformat: "yyyy-mm-dd",
            language: null
        });
        expect(session.hasRole("cash_all")).toBe(true);
        expect(session.hasRole("invalid role")).toBe(false);
    });
});
