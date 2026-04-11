/** @format */

/**
 * In native ESM mode (package.json "type": "module"), Jest does not
 * automatically inject the `jest` object into the global scope the way it
 * does in CJS mode.  Existing test files reference `jest.fn()` etc. as bare
 * globals, and @pinia/testing auto-detects Jest by checking
 * `typeof jest !== "undefined"`.  This setup file restores that expectation
 * by copying the jest object onto `globalThis` before any test file runs.
 */

import { jest } from "@jest/globals";

globalThis.jest = jest;
