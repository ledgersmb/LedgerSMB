/** @format */

import { beforeAll, afterAll, beforeEach, afterEach } from "@jest/globals";
import "core-js";
import { server } from "./mocks/server.js";
import { setGlobalOrigin } from "undici";

import "./mocks/lsmb_elements";

Object.defineProperty(window, "lsmbConfig", {
    writable: true,
    value: {
        version: "1.10",
        language: "en"
    }
});

// Enable i18n
import { config } from "@vue/test-utils";
import { i18n } from "../common/i18n";

config.global.plugins = [i18n];

beforeAll(() => {
    // Establish API mocking before all tests.
    server.listen({
        onUnhandledRequest(req) {
            console.error(
                "Found an unhandled %s request to %s",
                req.method,
                req.url.href
            );
        }
    });
});

afterAll(() => {
    // Clean up after the tests are finished.
    server.close();
});

beforeEach(() => {
    // Set the global origin (used by fetch) to the url provided in vitest.config.ts
    setGlobalOrigin(window.location.href);
});

// Reset any request handlers that we may add during the tests,
// so they don't affect other tests.
afterEach(() => {
    server.resetHandlers();
});

// Helper function to wait for DOM updates
// eslint no-unused-expressions: ["error", { "allowTernary": true }]
export const retry = (assertion, { interval = 20, timeout = 1000 } = {}) => {
    return new Promise((resolve, reject) => {
        const startTime = Date.now();

        const tryAgain = () => {
            setTimeout(() => {
                try {
                    resolve(assertion());
                } catch (err) {
                    // eslint-disable-next-line no-unused-expressions
                    Date.now() - startTime > timeout ? reject(err) : tryAgain();
                }
            }, interval);
        };

        tryAgain();
    });
};

window.retry = retry;
