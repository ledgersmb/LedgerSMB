/** @format */

/**
 * Vitest configuration for LedgerSMB UI tests.
 *
 * Two test projects mirror the previous Jest "browser" and "API" projects:
 *
 *   browser – component / store / view tests running in jsdom
 *             run alone:  yarn test:unit
 *
 *   API     – OpenAPI integration tests running in Node (need a real server)
 *             run alone:  yarn vitest run --project API
 *
 * Run all tests:  yarn test
 */

import { defineWorkspace } from "vitest/config";
import vue from "@vitejs/plugin-vue";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));

export default defineWorkspace([
    // ── browser project ────────────────────────────────────────────────────
    {
        plugins: [vue()],

        resolve: {
            alias: [
                // Keep the test-specific i18n mock so tests don't need
                // top-level-await (which the real src/i18n.js uses).
                {
                    find: /^@\/i18n$/,
                    replacement: resolve(__dirname, "tests/common/i18n.js")
                },
                // All other @/ imports resolve to src/
                {
                    find: "@/",
                    replacement: resolve(__dirname, "src") + "/"
                },
                // Resolve bare "images/…" imports (used in LoginPage.vue)
                // to the UI-level images directory.
                {
                    find: "images",
                    replacement: resolve(__dirname, "images")
                },
                // Stub out dijit/registry: the AMD module uses a Dojo loader
                // that is not available in the unit-test environment.
                {
                    find: /^dijit\/registry$/,
                    replacement: resolve(
                        __dirname,
                        "tests/common/mocks/dijit-registry.js"
                    )
                },
                // Force Quasar client build (not server/SSR build) so that
                // components using document/window APIs work in jsdom.
                {
                    find: /^quasar$/,
                    replacement: resolve(
                        __dirname,
                        "node_modules/quasar/dist/quasar.client.js"
                    )
                }
            ],
            // Allow imports without explicit .vue extension
            extensions: [".js", ".mjs", ".cjs", ".json", ".vue"]
        },

        test: {
            name: "browser",
            environment: "jsdom",

            include: ["tests/specs/**/*.spec.js"],
            exclude: ["tests/specs/openapi/**/*.spec.js"],

            globals: true,

            setupFiles: [
                "tests/common/vitest-polyfills.js",
                "tests/common/vitest-setup.js"
            ],

            coverage: {
                provider: "v8",
                reporter: ["text", "lcov"],
                reportsDirectory: "coverage",
                include: ["{src,js-src}/**/*.{js,vue}"],
                exclude: ["**/webpack*.js"]
            }
        }
    },

    // ── API project ─────────────────────────────────────────────────────────
    // These are integration tests that require a running LedgerSMB server
    // (LSMB_BASE_URL env var).  They are not run in the regular unit-test CI
    // step; they run in the test-webservices job via `make jstest`.
    {
        test: {
            name: "API",
            environment: "node",

            include: ["tests/specs/openapi/**/*.spec.js"],

            globals: true
        }
    }
]);
