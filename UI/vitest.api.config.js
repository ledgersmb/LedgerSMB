/** @format */

import { defineProject } from "vitest/config";

/**
 * API project for Vitest.
 * These are integration tests that require a running LedgerSMB server
 * (LSMB_BASE_URL env var). They are run in the test-webservices job.
 */
export default defineProject({
    test: {
        name: "API",
        environment: "node",
        hookTimeout: 30000,
        include: ["tests/specs/openapi/**/*.spec.js"],
        globals: true
    }
});
