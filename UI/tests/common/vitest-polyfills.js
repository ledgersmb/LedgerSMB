/** @format */
/* global globalThis */

/**
 * Vitest polyfills – runs before each test file in the "browser" project.
 *
 * Defines any globals that jsdom does not provide but our code or MSW needs.
 */

import { WritableStream } from "node:stream/web";

if (!globalThis.WritableStream) {
    Object.defineProperty(globalThis, "WritableStream", {
        value: WritableStream
    });
}

/**
 * Minimal AMD define() stub so that Dojo/Dijit AMD modules can be loaded
 * in the jsdom test environment without a real AMD loader.
 * Tests that need the actual Dojo-dependent behaviour should mock the
 * relevant modules directly.
 */
if (!globalThis.define) {
    globalThis.define = function amdStub(deps, factory) {
        if (typeof deps === "function") {
            // define(factory) – factory-only form
            return deps();
        }
        if (typeof factory === "function") {
            // define(deps, factory) – call with stub dependencies
            return factory(...deps.map(() => ({})));
        }
        return factory;
    };
    globalThis.define.amd = {};
}
