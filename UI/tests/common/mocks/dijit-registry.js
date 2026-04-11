/** @format */

/**
 * Test stub for dijit/registry.
 *
 * The real dijit/registry is an AMD module that requires a full Dojo runtime.
 * In unit tests we only need the module to load cleanly; any code that
 * actually calls registry.findWidgets() is exercised indirectly (e.g. form
 * validation) and those code paths do not affect the parts under test.
 */

export function findWidgets() {
    return [];
}

export function byId() {
    return null;
}

export function toArray() {
    return [];
}

export default { findWidgets, byId, toArray };
