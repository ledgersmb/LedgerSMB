/**
 * For a detailed explanation regarding each configuration property, visit:
 * https://jestjs.io/docs/configuration
 *
 * @format
 */

module.exports = {
    // All imported modules in your tests should be mocked automatically
    automock: false,

    // Stop running tests after `n` failures
    bail: 0,

    // The directory where Jest should store its cached dependency information
    cache: true,
    cacheDirectory: "/tmp/jest_rs",

    // Automatically clear mock calls, instances, contexts and results before every test
    // clearMocks: true,

    // Indicates whether the coverage information should be collected while executing the test
    collectCoverage: false,

    // An array of glob patterns indicating a set of files for which coverage information should be collected
    collectCoverageFrom: ["{src,js-src}/**/*.{js,vue}", "!**/webpack*.js"],

    // The directory where Jest should output its coverage files
    coverageDirectory: "coverage",

    // An array of regexp pattern strings used to skip coverage collection
    coveragePathIgnorePatterns: ["node_modules", "<rootDir>/tests/*.*"],

    // Indicates which provider should be used to instrument code for coverage
    coverageProvider: "v8",

    // A list of reporter names that Jest uses when writing coverage reports
    coverageReporters: ["text", "lcov"],

    // An object that configures minimum threshold enforcement for coverage results
    // coverageThreshold: undefined,

    // A path to a custom dependency extractor
    // dependencyExtractor: undefined,

    detectLeaks: false,
    detectOpenHandles: true,

    // Make calling deprecated APIs throw helpful error messages
    errorOnDeprecated: true,

    expand: true,
    extensionsToTreatAsEsm: [],

    // The default configuration for fake timers
    fakeTimers: {
        enableGlobally: false
    },

    // Force Jest to exit after all tests have completed running.
    // This is useful when resources set up by test code cannot be adequately cleaned up.
    forceExit: true,

    // Force coverage collection from ignored files using an array of glob patterns
    forceCoverageMatch: [],

    // A path to a module which exports an async function that is triggered once before all test suites
    // globalSetup: undefined,

    // A path to a module which exports an async function that is triggered once after all test suites
    // globalTeardown: undefined,

    // A set of global variables that need to be available in all test environments
    // globals: {},

    haste: {
        computeSha1: false,
        enableSymlinks: false,
        forceNodeFilesystemAPI: true,
        throwOnModuleCollision: false
    },

    // Insert Jest's globals (expect, test, describe, beforeEach etc.) into the global environment.
    // If you set this to false, you should import from @jest/globals
    injectGlobals: true,

    // Prints the test results in JSON. This mode will send all other test output and user messages to stderr.
    json: false,

    // Run all tests affected by file changes in the last commit made
    lastCommit: false,

    // Lists all test files that Jest will run given the arguments, and exits.
    listTests: false,

    // Logs the heap usage after every test. Useful to debug memory leaks.
    logHeapUsage: false,

    // Prevents Jest from executing more than the specified amount of tests at the same time. Only affects tests that use test.concurrent
    maxConcurrency: 5,

    // The maximum amount of workers used to run your tests. Can be specified as % or a number. E.g. maxWorkers: 10% will use 10% of your CPU amount + 1 as the maximum worker number. maxWorkers: 2 will use a maximum of 2 workers.
    maxWorkers: 1, // "50%",

    // An array of directory names to be searched recursively up from the requiring module's location
    moduleDirectories: ["node_modules"],

    // An array of file extensions your modules use
    moduleFileExtensions: ["js", "json", "vue"],

    // A map from regular expressions to module names or to arrays of module names that allow to stub out resources with a single module

    // An array of regexp pattern strings, matched against all module paths before considered 'visible' to the module loader
    modulePathIgnorePatterns: [],

    // Disables stack trace in test results output.
    noStackTrace: false,

    // Activates notifications for test results
    notify: false,

    // An enum that specifies notification mode. Requires { notify: true }
    notifyMode: "failure-change",

    // Attempts to identify which tests to run based on which files have changed in the current repository.
    // Only works if you're running tests in a git/hg repository at the moment and requires a static dependency graph
    onlyChanged: false,
    onlyFailures: false,

    // Allows the test suite to pass when no files are found
    passWithNoTests: false,

    prettierPath: "prettier",

    // A preset that is used as a base for Jest's configuration
    // preset: 'ts-jest',

    // Run tests from one or more projects, found in the specified paths; also takes path globs.
    // This option is the CLI equivalent of the projects configuration option.
    // Note that if configuration files are found in the specified paths, all projects specified within those configuration files will be run.
    projects: [
        {
            displayName: "browser",
            moduleFileExtensions: ["js", "json", "vue"],
            moduleNameMapper: {
              "^@/i18n": "<rootDir>/tests/common/i18n", // Jest doesn't support esm or top level await well
              "^quasar$": "<rootDir>/node_modules/quasar/dist/quasar.client.js",
              "^@/(.*)$": "<rootDir>/src/$1"
            },
            testMatch: [ "<rootDir>/tests/specs/**/*.spec.js" ],
            setupFiles: ["<rootDir>/tests/common/jest.polyfills.js"],
            setupFilesAfterEnv: [ "<rootDir>/tests/common/jest-setup.js" ],
            testEnvironment: "jest-fixed-jsdom",
            testEnvironmentOptions: {
                customExportConditions: ["node", "node-addons"]
            },
            testPathIgnorePatterns: [ "<rootDir>/tests/specs/openapi/.*\\.spec\\.js" ],
            transformIgnorePatterns: [ '/node_modules/(?!(lodash-es|quasar)/)' ],
            transform: {
                "^.+\\.yaml$": "yaml-jest-transform",
                "^.+\\.js$": "babel-jest",
                "^.+\\.vue$": "@vue/vue3-jest",
                "^@": "babel-jest",

            },
        },
        {
            displayName: "API",
            moduleFileExtensions: ["js", "json", "vue"],
            testMatch: [ "<rootDir>/tests/specs/openapi/**/*.spec.js" ],
            testEnvironment: "node",
            transform: {
                "^.+\\.yaml$": "yaml-jest-transform",
                "^.+\\.js$": "babel-jest",
                "^.+\\.vue$": "@vue/vue3-jest",
                "^@": "babel-jest",
            },
        }
    ],

    // Use this configuration option to add custom reporters to Jest
    // reporters: [],

    // Automatically reset mock state before every test
    resetMocks: false,

    // Reset the module registry before running each individual test
    resetModules: false,

    // A path to a custom resolver
    // resolver: undefined,

    // Automatically restore mock state and implementation before every test
    restoreMocks: false,

    // The root directory that Jest should scan for tests and modules within
    // rootDir: ".",

    // A list of paths to directories that Jest should use to search for files in
    // roots: [
    //   "<rootDir>"
    // ],

    // Allows you to use a custom runner instead of Jest's default test runner
    // runner: "groups",

    // Run all tests serially in the current process, rather than creating a worker pool of child processes that run tests. This can be useful for debugging.
    // runInBand: false,

    // Run only the tests that were specified with their exact paths.
    runTestsByPath: false,

    sandboxInjectedGlobals: [],

    // The paths to modules that run some code to configure or set up the testing environment before each test
    // setupFiles: ["<rootDir>/tests/common/jest.polyfills.js"],

    // A list of paths to modules that run some code to configure or set up the testing framework before each test
    setupFilesAfterEnv: [],

    skipFilter: false,

    // The number of seconds after which a test is considered as slow and reported as such in the results.
    slowTestThreshold: 5,

    // A list of paths to snapshot serializer modules Jest should use for snapshot testing
    snapshotSerializers: ["jest-serializer-vue"],

    // The test environment that will be used for testing
    testEnvironment: "jest-fixed-jsdom",

    // Options that will be passed to the testEnvironment
    testEnvironmentOptions: {
        customExportConditions: ["node", "node-addons"]
    },

    // Adds a location field to test results
    testLocationInResults: false,

    // The glob patterns Jest uses to detect test files
    testMatch: [
        "**/__tests__/**/*.[jt]s?(x)",
        "**/?(*.)+(spec|test).[tj]s?(x)"
    ],

    // An array of regexp pattern strings that are matched against all test paths, matched tests are skipped
    testPathIgnorePatterns: ["node_modules/", "tmp/", ".vscode/"],

    // The regexp pattern or array of patterns that Jest uses to detect test files
    testRegex: [],

    // This option allows the use of a custom results processor
    // testResultsProcessor: undefined,

    // This option allows use of a custom test runner
    testRunner: "jest-circus/runner",

    // A map from regular expressions to paths to transformers
    transform: {
        "^.+\\.yaml$": "yaml-jest-transform",
        "^.+\\.js$": "babel-jest",
        "^@": "babel-jest",
        "^.+\\.vue$": "@vue/vue3-jest"
    },

    // An array of regexp pattern strings that are matched against all source file paths, matched files will skip transformation
    transformIgnorePatterns: [ '/node_modules/(?!(lodash-es|@quasar)/)' ],

    // An array of regexp pattern strings that are matched against all modules before the module loader will automatically return a mock for them
    // unmockedModulePathPatterns: undefined,

    // Use this flag to re-record every snapshot that fails during this test run.
    // Can be used together with a test suite pattern or with --testNamePattern to re-record snapshots.
    updateSnapshot: true,

    // Divert all output to stderr.
    useStderr: false,

    // Indicates whether each individual test should be reported during the run
    verbose: true,

    // Watch files for changes and rerun tests related to changed files.
    // If you want to re-run all tests when a file has changed, use the --watchAll option instead.
    watch: false,

    // An array of regexp patterns that are matched against all source file paths before re-running tests in watch mode
    watchPathIgnorePatterns: [],

    // Whether to use watchman for file crawling
    watchman: true
};
