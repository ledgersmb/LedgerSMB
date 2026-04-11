/**
 * @format
 *
 * ESM compatibility shim for @ehuelsmann/jest-openapi.
 *
 * The package is compiled from TypeScript/ESM source and ships as CJS with
 * the `{ __esModule: true, default: fn }` envelope.  When imported from a
 * native ESM module Jest's loadCjsAsEsm() makes the whole `module.exports`
 * the ESM default, so `import jestOpenAPI from "@ehuelsmann/jest-openapi"`
 * would yield the envelope object rather than the callable function.
 *
 * This shim re-exports the unwrapped function as the default export so that
 * the moduleNameMapper entry for "@ehuelsmann/jest-openapi" works correctly.
 *
 * Note: we load the package via its real dist path (not the package name) so
 * that Jest's moduleNameMapper does not redirect back to this shim file.
 */
import { createRequire } from "node:module";

const _require = createRequire(import.meta.url);
// Load the CJS dist directly to avoid moduleNameMapper circular redirect
const mod = _require("../../../node_modules/@ehuelsmann/jest-openapi/dist/index.js");
export default mod.default ?? mod;
