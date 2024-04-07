/** @format */

import globals from "globals";
import babelParser from "@babel/eslint-parser";
// import compatPlugin from "eslint-plugin-compat";
import eslintConfigESLint from "eslint-config-eslint";
import eslintPluginPrettierRecommended from "eslint-plugin-prettier/recommended";
// import importPlugin from "eslint-plugin-import";
import js from "@eslint/js";
import jest from "eslint-plugin-jest";
import packageJson from "eslint-plugin-package-json/configs/recommended";
import pluginVue from "eslint-plugin-vue";

export default [
    js.configs.recommended,
    eslintPluginPrettierRecommended,
    ...pluginVue.configs["flat/recommended"], // Why global?
    // compatPlugin.configs["flat/recommended"],
    // importPlugin.configs["flat/recommended"],

    // Global config
    {
        ignores: ["{js,node_modules,__mocks__}/**/*.js"]
    },
    // Config files
    {
        ...eslintConfigESLint,
        files: ["**/*.config.m?js"]
    },
    // JavaScript files
    {
        files: ["**/*.js"],
        ignores: ["**/*.spec.js", "**/*.config.m?js"],
        languageOptions: {
            globals: {
                ...globals.browser,
                ...globals.es6,
                ...globals.amd,
                ...globals.node
            },
            ecmaVersion: 6,
            sourceType: "module",
            parser: babelParser,
            parserOptions: {
                requireConfigFile: false,
                templateSettings: {
                    evaluate: ["[%", "%]"],
                    interpolate: ["[%", "%]"],
                    escape: ["[%", "%]"]
                }
            }
        },
        plugins: {
            // "compat", // Not yet compatible with eslint 9
            // "import", // Not yet compatible with eslint 9
        },
        rules: {
            ...js.configs.recommended.rules,
            camelcase: "off",
            // "compat/compat": "warn", // Not yet compatible with eslint 9
            "consistent-return": "error",
            curly: ["error", "all"],
            "dot-notation": "error",
            eqeqeq: "error",
            "func-names": 0,
            "global-require": "error",
            "guard-for-in": "error",
            "new-cap": 0,
            "no-alert": "error",
            "no-console": "error",
            "no-continue": 0,
            "no-else-return": "error",
            "no-lonely-if": "error",
            "no-multi-assign": "error",
            "no-multi-spaces": "off",
            "no-new-object": "error",
            "no-param-reassign": "error",
            "no-plusplus": 0,
            "no-restricted-globals": "error",
            "no-shadow": "error",
            "no-template-curly-in-string": "error",
            "no-undef": "error",
            "no-underscore-dangle": 0,
            "no-unused-expressions": "error",
            "no-unused-vars": "error",
            "no-use-before-define": "error",
            "no-useless-escape": "error",
            "no-useless-return": "error",
            "one-var": [
                "error",
                {
                    initialized: "never",
                    uninitialized: "consecutive"
                }
            ],
            radix: "error",
            "spaced-comment": [
                "error",
                "always",
                {
                    block: {
                        balanced: true
                    }
                }
            ],
            "vars-on-top": 0,
            yoda: "error",
            "no-restricted-syntax": ["error", "SequenceExpression"]
        }
    },
    // Package.json
    {
        files: ["package.json"],
        ...packageJson,
        rules: {
            ...packageJson.rules,
            "package-json/order-properties": [
                "error",
                {
                    order: [
                        "name",
                        "version",
                        "lockfileVersion",
                        "private",
                        "publishConfig",
                        "description",
                        "keywords",
                        "author",
                        "license",
                        "maintainers",
                        "contributors",
                        "bundlesize",
                        "main",
                        "browser",
                        "_browserslist-comment",
                        "browserslist",
                        "bugs",
                        "repository",
                        "files",
                        "bin",
                        "directories",
                        "man",
                        "config",
                        "dependencies",
                        "devDependencies",
                        "peerDependencies",
                        "optionalDependencies",
                        "bundledDependencies",
                        "homepage",
                        "scripts",
                        "engines",
                        "os",
                        "cpu",
                        "babel",
                        "eslintConfig",
                        "prettier",
                        "stylelint",
                        "lint-staged"
                    ]
                }
            ],
            "package-json/sort-collections": [
                "error",
                ["scripts", "devDependencies", "dependencies", "config"]
            ],
            "prettier/prettier": [
                "error",
                {
                    tabWidth: 2
                }
            ]
        }
    },
    // Test files
    {
        files: [
            "**/__tests__/**/*.[jt]s?(x)",
            "**/?(*.)+(spec|test).[tj]s?(x)"
        ],
        ...jest.configs["flat/recommended"],
        rules: {
            ...jest.configs["flat/recommended"].rules,
            "jest/prefer-expect-assertions": "off",
            "jest/no-commented-out-tests": "off",
            "jest/no-disabled-tests": "warn",
            "jest/no-focused-tests": "error",
            "jest/no-identical-title": "error",
            "jest/prefer-to-have-length": "warn",
            "jest/valid-expect": "error",
            "no-console": "off",
            camelcase: "off"
        }
    },
    // Vue files
    {
        files: ["**/*.vue"],
        rules: {
            "vue/attribute-hyphenation": "off",
            "vue/block-order": [
                "error",
                {
                    order: [
                        "script:not([setup])",
                        "script[setup]",
                        "template",
                        "style:not([scoped])",
                        "style[scoped]"
                    ]
                }
            ],
            "vue/first-attribute-linebreak": "off",
            "vue/html-indent": ["error", 4],
            "vue/multi-word-component-names": "off",
            "vue/no-setup-props-reactivity-loss": "off",
            "vue/require-prop-types": "off"
        }
    }
];
