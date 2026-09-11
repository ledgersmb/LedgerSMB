/** @format */
"use strict";

/**
 * Temporary scaffold for rewriting dojo-webpack-plugin's CommonJS wrapper
 * output into ESM before webpack emits the final bundle.
 *
 * The intended implementation will:
 * - parse the generated wrapper with Babel
 * - rewrite module.exports / exports.* assignments into ESM exports
 * - preserve source maps where possible
 *
 * Expected future dependencies:
 * - @babel/parser
 * - @babel/traverse
 * - @babel/generator
 */

function cjsToEsmLoader(source, inputSourceMap) {
    const result = transformCommonJSWrapperToEsm(source, this.resourcePath);

    if (result.map === null && inputSourceMap) {
        result.map = inputSourceMap;
    }

    this.callback(null, result.code, result.map, null);
}

function transformCommonJSWrapperToEsm(source, resourcePath) {
    const wrapper = String(source);

    // TODO: replace this scaffold with an AST-based transform.
    // The real implementation should only convert the dojo-webpack-plugin
    // wrapper shape and leave the rest of the module graph untouched.
    if (!looksLikeCommonJSWrapper(wrapper)) {
        return {
            code: wrapper,
            map: null
        };
    }

    return {
        code: wrapper,
        map: null,
        resourcePath
    };
}

function looksLikeCommonJSWrapper(source) {
    return (
        source.includes("module.exports") ||
        source.includes("exports.") ||
        source.includes("require(")
    );
}

module.exports = cjsToEsmLoader;
module.exports.transformCommonJSWrapperToEsm = transformCommonJSWrapperToEsm;
