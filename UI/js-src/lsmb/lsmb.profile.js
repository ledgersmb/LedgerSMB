/*
 * Created by john on 2/21/16.
 * Modified by ylavoie 2016-04-27 for amd
 */
var copyOnlyMids = {
//        "lsmb/package": 1
};
var miniExcludeMids = {
//      "lsmb/README.md": 1,
        "lsmb/package": 1
};

// jshint unused: false
var profile = (function(){
    return {
        basePath: ".",
        // releaseDir = <root>/UI/jsJ
        releaseDir: "../../js",
        releaseName: "",
        action: "release",
        // Usual Dojo optimizer is Google Closure.
        // See http://lisperator.net/uglifyjs/ for UglifyJS
        layerOptimize: "uglify",
        optimize: "uglify",
        cssOptimize: "comments",
        mini: true,
        stripConsole: "warn",
        selectorEngine: "lite",

        defaultConfig: {
            hasCache:{
                "dojo-built": 1,
                "dojo-loader": 1,
                "dom": 1,
                "host-browser": 1,
                "config-selectorEngine": "lite"
            },
            async: 1
        },

        staticHasFeatures: {
            "config-deferredInstrumentation": 0, // Disables automatic loading of code that reports un-handled rejected promises
            "config-dojo-loader-catches":     0, // Disables some of the error handling when loading modules.
            "config-tlmSiblingOfDojo":        0, // Disables non-standard module resolution code.
            "dojo-amd-factory-scan":          0, // Assumes that all modules are AMD
            "dojo-combo-api":                 0, // Disables some of the legacy loader API
            "dojo-config-api":                1, // Ensures that the build is configurable
            "dojo-config-require":            0, // Disables configuration via the require().
            "dojo-debug-messages":            0, // Disables some diagnostic information
            "dojo-dom-ready-api":             1, // Ensures that the DOM ready API is available
            "dojo-firebug":                   0, // Disables Firebug Lite for browsers that don"t have a developer console (e.g. IE6)
            "dojo-guarantee-console":         1, // Ensures that the console is available in browsers that don"t have it available (e.g. IE6)
            "dojo-has-api":                   1, // Ensures the has feature detection API is available.
            "dojo-inject-api":                1, // Ensures the cross domain loading of modules is supported
            "dojo-loader":                    1, // Ensures the loader is available
            "dojo-log-api":                   0, // Disables the logging code of the loader
            "dojo-modulePaths":               0, // Removes some legacy API related to loading modules
            "dojo-moduleUrl":                 0, // Removes some legacy API related to loading modules
            "dojo-publish-privates":          0, // Disables the exposure of some internal information for the loader.
            "dojo-requirejs-api":             0, // Disables support for RequireJS
            "dojo-sniff":                     1, // Enables scanning of data-dojo-config and djConfig in the dojo.js script tag
            "dojo-sync-loader":               0, // Disables the legacy loader
            "dojo-test-sniff":                0, // Disables some features for testing purposes
            "dojo-timeout-api":               0, // Disables code dealing with modules that don"t load
            "dojo-trace-api":                 0, // Disables the tracing of module loading.
            "dojo-undef-api":                 0, // Removes support for module unloading
            "dojo-v1x-i18n-Api":              1, // Enables support for v1.x i18n loading (required for Dijit)
            "dom":                            1, // Ensures the DOM code is available
            "host-browser":                   1, // Ensures the code is built to run on a browser platform
            "extend-dojo":                    1  // Ensures pre-Dojo 2.0 behavior is maintained
            },

        packages:[{
            name: "dojo",
            location: "../dojo"
        },{
            name: "dijit",
            location: "../dijit"
        },{
            name: "lsmb",
            location: "."
        }],

        layers: {
            "dojo/dojo": {
                include: [ "dojo/dojo", "dojo/query",
                           "dojo/domReady", "dojo/on", "dijit/Tooltip" ],
                customBase: true,
                boot: true
            },
            "lsmb/main": {
                include: [
                    "lsmb/DateTextBox",
                    "lsmb/Form",
                    "lsmb/Invoice",
                    "lsmb/InvoiceLine",
                    "lsmb/InvoiceLines",
                    "lsmb/MainContentPane",
                    "lsmb/MaximizeMinimize",
                    "lsmb/PrintButton",
                    "lsmb/PublishCheckBox",
                    "lsmb/PublishNumberTextBox",
                    "lsmb/PublishRadioButton",
                    "lsmb/PublishSelect",
                    "lsmb/SetupLoginButton",
                    "lsmb/SubscribeCheckBox",
                    "lsmb/SubscribeNumberTextBox",
                    "lsmb/SubscribeSelect",
                    "lsmb/SubscribeShowHide",
                    "lsmb/TabularForm"
                ]
            }
        },

        resourceTags: {
                copyOnly: function (filename, mid) {
                        return mid in copyOnlyMids;
                },

                test: function (filename) {
                        return /\/test\//.test(filename);
                },

                miniExclude: function (filename, mid) {
                        return (/\/(?:test|demos)\//).test(filename) ||
                                (/\.styl$/).test(filename) ||
                                mid in miniExcludeMids;
                },

                amd: function (filename) {
                        return (/lsmb\/.+\.js$/).test(filename);
                }
        }
    };
})();
