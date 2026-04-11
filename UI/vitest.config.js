/** @format */

/**
 * Vitest configuration for LedgerSMB UI tests.
 *
 * The test suite is split into two named projects (see vitest.workspace.js):
 *
 *   browser – component / store / view tests running in jsdom
 *             run alone:  yarn test:unit
 *
 *   API     – OpenAPI integration tests running in Node (require a live server)
 *             run alone:  yarn vitest run --project API
 *
 * Run all tests:  yarn test
 */

import { defineConfig } from "vitest/config";

export default defineConfig({
    test: {
        // The workspace file defines all individual projects.
        workspace: "vitest.workspace.js",
        coverage: {
            enabled: true,
            provider: "v8",
            reporter: ["text", "html", ["lcov", { file: "lcov.info" }]],
            include: ["{src,js-src}/**/*.{js,vue}"],
            exclude: ["**/webpack*.js"]
        }
    }
});
