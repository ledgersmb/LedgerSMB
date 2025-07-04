
```plain
 FAIL  tests/specs/components/PartsGroupTreeNode.spec.js
  ● Test suite failed to run

    Jest encountered an unexpected token

    Jest failed to parse a file. This happens e.g. when your code or its dependencies use non-standard JavaScript syntax, or when Jest is not configured to support such syntax.

    Out of the box Jest supports Babel, which will be used to transform your files into valid JS based on your Babel configuration.

    By default "node_modules" folder is ignored by transformers.

    Here's what you can do:
     • If you are trying to use ECMAScript Modules, see https://jestjs.io/docs/ecmascript-modules for how to enable it.
     • If you are trying to use TypeScript, see https://jestjs.io/docs/getting-started#using-typescript
     • To have some of your "node_modules" files transformed, you can specify a custom "transformIgnorePatterns" in your config.
     • If you need a custom transformation, specify a "transform" option in your config.
     • If you simply want to mock your non-JS modules (e.g. binary assets) you can stub them out with the "moduleNameMapper" config option.

    You'll find more details and examples of these config options in the docs:
    https://jestjs.io/docs/configuration
    For information about custom transformations, see:
    https://jestjs.io/docs/code-transformation

    Details:

    /srv/ledgersmb/UI/node_modules/lodash-es/lodash.js:10
    export { default as add } from './add.js';
    ^^^^^^

    SyntaxError: Unexpected token 'export'

      2 |
      3 | import { describe, expect, it } from "@jest/globals";
    > 4 | import { installQuasarPlugin, qLayoutInjections } from '@quasar/quasar-app-extension-testing-unit-jest';
        | ^
      5 | import { mount } from "@vue/test-utils";
      6 |
      7 | import PartsGroupTreeNode from "@/components/PartsGroupTreeNode";

      at Runtime.createScriptFromCode (node_modules/jest-runtime/build/index.js:1320:40)
      at Object.<anonymous> (node_modules/@quasar/quasar-app-extension-testing-unit-jest/src/helpers/install-quasar-plugin.ts:3:1)
      at Object.<anonymous> (node_modules/@quasar/quasar-app-extension-testing-unit-jest/src/helpers/main.ts:1:1)
      at Object.require (tests/specs/components/PartsGroupTreeNode.spec.js:4:1)
```