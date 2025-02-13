/** @format */

import globals from "globals";
import babelParser from "@babel/eslint-parser";
import compatPlugin from "eslint-plugin-compat";
import eslintConfigESLint from "eslint-config-eslint";
import eslintPluginPrettierRecommended from "eslint-plugin-prettier/recommended";
import eslintImportX from "eslint-plugin-import-x";
import js from "@eslint/js";
import jest from "eslint-plugin-jest";
import packageJson from "eslint-plugin-package-json/configs/recommended";
import pluginVue from "eslint-plugin-vue";

export default [
    // Global config
    {
        ignores: ["{js/**/*,node_modules/**/*,__mocks__/**/*}"]
    },

    js.configs.recommended,
    eslintPluginPrettierRecommended,
    ...pluginVue.configs["flat/recommended"],
    compatPlugin.configs["flat/recommended"],

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
                ...globals.amd,
                ...globals.node
            },
            ecmaVersion: 6,
            sourceType: "module",
            parser: babelParser,
            parserOptions: {
                requireConfigFile: false,
                babelOptions: {
                    babelrc: false,
                    configFile: false,
                    presets: ["@babel/preset-env"]
                },
                templateSettings: {
                    evaluate: ["[%", "%]"],
                    interpolate: ["[%", "%]"],
                    escape: ["[%", "%]"]
                }
            }
        },
        plugins: {
            "import-x": eslintImportX
        },
        settings: {
            "import-x/resolver": "webpack",
            "import-x/parsers": {
                "@babel/eslint-parser": [".js"]
            }
        },
        rules: {
            ...js.configs.recommended.rules,
            camelcase: "error",
            "compat/compat": "warn",
            "consistent-return": "error",
            curly: ["error", "all"],
            "dot-notation": "error",
            eqeqeq: "error",
            "func-names": 0,
            "global-require": "error",
            "guard-for-in": "error",
            "import-x/export": "error",
            "import-x/named": "error",
            "import-x/namespace": "error",
            "import-x/default": "error",
            "import-x/no-absolute-path": "error",
            "import-x/no-dynamic-require": "error",
            "import-x/no-named-as-default": "warn",
            "import-x/no-named-as-default-member": "warn",
            "import-x/no-duplicates": "warn",
            "new-cap": 0,
            "no-alert": "error",
            "no-continue": 0,
            "no-else-return": "error",
            "no-eval": "error",
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
            "vars-on-top": "off",
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
        files: ["src/**/*.vue"],
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
            "vue/html-closing-bracket-newline": "off",
            "vue/html-indent": ["error", 4],
            "vue/html-self-closing": "off",
            "vue/max-attributes-per-line": [
                "error",
                {
                    singleline: 3,
                    multiline: 3
                }
            ],
            "vue/multi-word-component-names": "off",
            "vue/multiline-html-element-content-newline": "off",
            "vue/no-setup-props-reactivity-loss": "off",
            "vue/require-prop-types": "off",
            "vue/singleline-html-element-content-newline": [
                "error",
                {
                    ignoreWhenNoAttributes: true,
                    ignoreWhenEmpty: true,
                    ignores: ["pre", "textarea", "template"],
                    externalIgnores: []
                }
            ],
            "vue/v-on-event-hyphenation": "off"
        }
    }
];
