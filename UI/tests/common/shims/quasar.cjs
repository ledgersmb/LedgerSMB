'use strict';
/**
 * quasar.cjs — Jest shim for Quasar in native-ESM test mode.
 *
 * Quasar 2 ships as an ESM-only package ("type":"module") so it cannot be
 * required directly by Jest's CJS runtime.  The server-rendered build
 * (quasar.server.prod.cjs) is the only pre-built CJS artifact and is what
 * Jest resolves via moduleNameMapper.
 *
 * Problem: quasar.server.prod.cjs expects an SSR context object as the third
 * argument of `Quasar.install(app, opts, ssrContext)`:
 *   - `ve()` calls `Object.assign(ssrContext, { $q, _meta, … })` — crashes when
 *     ssrContext is undefined (vue-test-utils calls install with only 2 args).
 *   - The Platform plugin's `parseSSR(ssrContext)` accesses
 *     `ssrContext.req.headers` — crashes if req is absent.
 *
 * Fix: load the server CJS build, patch Quasar.install in-place so a minimal
 * test-safe ssrContext is substituted whenever the caller omits it, then
 * re-export the entire module.  Using `module.exports = require(...)` allows
 * Jest's cjs-module-lexer to follow the reexport chain and expose every named
 * export (Quasar, QBtn, QIcon, …) as a proper ESM named binding.
 */

// Minimal ssrContext that satisfies all auto-installed Quasar SSR plugins:
//   - req.headers   : Platform plugin's parseSSR reads user-agent header
//   - res.setHeader : Cookies plugin may call res.setHeader (no-op in tests)
//   - onRendered    : Meta plugin calls ssrContext.onRendered(cb); ve() will
//                     default it to ()=>{} but we supply a working one just in
//                     case ve() has already run before our patch.
const _testSsrCtx = {
    req: { headers: {} },
    res: { setHeader: () => {} },
    _modules: [],
    onRendered: () => {}
};

const _quasar = require('../../../node_modules/quasar/dist/quasar.server.prod.cjs');
const _origInstall = _quasar.Quasar.install;
_quasar.Quasar.install = function install(app, opts, ssrContext) {
    return _origInstall.call(
        _quasar.Quasar,
        app,
        opts ?? {},
        ssrContext ?? Object.assign({}, _testSsrCtx)
    );
};

// Re-export the patched module.  The `module.exports = require(...)` pattern
// lets cjs-module-lexer walk the reexport chain and surface all named exports.
module.exports = require('../../../node_modules/quasar/dist/quasar.server.prod.cjs');
