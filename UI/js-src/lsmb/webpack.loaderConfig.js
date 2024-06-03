/*
 * (C) Copyright IBM Corp. 2012, 2016 All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @format
 */
const path = require("path");

function getConfig(/* env */) {
    // env is set by the 'buildEnvironment' and/or 'environment' plugin options
    // (see webpack.config.js),
    // or by the code at the end of this file if using without webpack
    return {
        packages: [
            // An array of objects which provide the package name and location
            {
                name: "dojo",
                location: path.resolve(__dirname, "../../node_modules/dojo")
            },
            {
                name: "dijit",
                location: path.resolve(__dirname, "../../node_modules/dijit")
            },
            {
                name: "lsmb", // the name of the package
                location: "js-src/lsmb" // the directory path where it resides
            }
        ],

        async: true, // Defines if Dojo core should be loaded asynchronously
        blankGif: "./js/dojo/resources/blank.gif",
        deps: [], // An array of resource paths which should load immediately once Dojo has loaded:

        has: {
            "dojo-config-api": 1, // Ensures that the build is configurable
            "dojo-has-api": 1 // Ensures the has feature detection API is available.
            /*
            'host-browser':                   1, // Ensures the code is built to run on a browser platform
            'dojo-config-require':            1, // Enables configuration via the require().
            'dojo-v1x-i18n-Api':              1, // Enables support for v1.x i18n loading (required for Dijit)
            'dojo-dom-ready-api':             1, // Ensures that the DOM ready API is available
            'dom':                            1, // Ensures the DOM code is available
            'extend-dojo':                    1, // Ensures pre-Dojo 2.0 behavior is maintained
            'dojo-guarantee-console':         1, // Ensures that the console is available in browsers that don't have it available (e.g. IE6)
            'dojo-inject-api':                1, // Ensures the cross domain loading of modules is supported
            'dojo-loader':                    1, // Ensures the loader is available

            'config-deferredInstrumentation': 1, // Disables automatic loading of code that reports un-handled rejected promises
            'config-dojo-loader-catches':     1, // Disables some of the error handling when loading modules.
            'config-tlmSiblingOfDojo':        1, // Disables non-standard module resolution code.
            'dojo-amd-factory-scan':          1, // Assumes that all modules are AMD
            'dojo-combo-api':                 1, // Disables some of the legacy loader API
            'dojo-debug-messages':            1, // Disables some diagnostic information
            'dojo-firebug':                   0, // Disables Firebug Lite for browsers that don't have a developer console (e.g. IE6)
            'dojo-log-api':                   1, // Disables the logging code of the loader
            'dojo-modulePaths':               1, // Removes some legacy API related to loading modules
            'dojo-moduleUrl':                 1, // Removes some legacy API related to loading modules
            'dojo-publish-privates':          1, // Disables the exposure of some internal information for the loader.
            'dojo-requirejs-api':             1, // Disables support for RequireJS
            'dojo-sniff':                     0, // Enables scanning of data-dojo-config and djConfig in the dojo.js script tag
            'dojo-sync-loader':               0, // Disables the legacy loader
            'dojo-test-sniff':                0, // Disables some features for testing purposes
            'dojo-timeout-api':               1, // Disables code dealing with modules that don't load
            'dojo-trace-api':                 1, // Disables the tracing of module loading.
            'dojo-undef-api':                 0, // Removes support for module unloading
*/
        }
    };
}
// For Webpack, export the config.
// This is needed both at build time and on the client at runtime
if (typeof module !== "undefined") {
    module.exports = getConfig;
} else {
    // No webpack.  This script was loaded by page via script tag, so load Dojo from CDN
    getConfig(/* { dojoRoot: "//ajax.googleapis.com/ajax/libs/dojo/1.16.0" } */);
}
