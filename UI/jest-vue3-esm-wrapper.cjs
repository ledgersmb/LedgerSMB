/**
 * @format
 *
 * Custom Jest transformer for Vue 3 SFCs in native-ESM mode.
 *
 * @vue/vue3-jest@29 outputs CommonJS code (require/exports).  That is fine
 * for Jest's CJS runtime, but when an ESM test file (identified by the nearest
 * package.json having "type":"module") *imports* a Vue SFC, Jest's
 * loadCjsAsEsm() helper wraps the whole module.exports as the ESM default
 * export.  Because vue3-jest puts the component under exports.default (not as
 * module.exports directly), the test would receive
 *   `{ default: component, render: fn, __esModule: true }`
 * instead of just the component – causing "Invalid vnode type: undefined" Vue
 * warnings and test failures.
 *
 * This wrapper:
 *   1. Delegates all actual Vue-SFC compilation to @vue/vue3-jest.
 *   2. Appends a short normalisation tail that replaces module.exports with
 *      module.exports.default when the CJS-compiled module carries an
 *      __esModule marker (i.e. was originally an ES-module).  After the swap
 *      `import Component from "…vue"` yields the component object directly.
 */

'use strict';

const vue3jest = require('@vue/vue3-jest');
const crypto = require('crypto');
const babelJest = require('babel-jest').default;

const ESM_NORMALISATION_TAIL = `
// vue3-jest-esm-wrapper: make the default export available as module.exports
// so that Jest's CJS→ESM bridge (loadCjsAsEsm) returns the component directly
// when the file is imported from an ESM module.
if (typeof module !== 'undefined' &&
    module.exports &&
    module.exports.__esModule &&
    module.exports.default != null) {
  module.exports = module.exports.default;
}
`;

module.exports = {
    process(sourceText, sourcePath, options) {
        const result = vue3jest.process(sourceText, sourcePath, options);
        return {
            code: result.code + ESM_NORMALISATION_TAIL,
            map: result.map
        };
    },

    getCacheKey(sourceText, sourcePath, options) {
        // Include a version string so that cache is invalidated if we change
        // this wrapper logic.
        const baseKey = babelJest
            .createTransformer()
            .getCacheKey(sourceText, sourcePath, options);
        return crypto
            .createHash('md5')
            .update(baseKey)
            .update('vue3-jest-esm-wrapper-v1')
            .digest('hex');
    }
};
