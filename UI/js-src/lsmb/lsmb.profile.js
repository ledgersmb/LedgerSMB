/**
 *
 * Created by john on 2/21/16.
 */
var profile = (function(){
    return {
        basePath: ".",
        // releaseDir = <root>/UI/jsJ
        releaseDir: "../../js",
        releaseName: "",
        action: "release",
        layerOptimize: "closure.keeplines",
        optimize: "closure",
        cssOptimize: "comments",
        mini: true,
        stripConsole: "warn",
        selectorEngine: "lite",
        resourceTags: {
            // tag all .js files as modules
            amd: function(filename, mid) {
                return /\.js$/.test(filename);
            }
        },

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
            "config-deferredInstrumentation": 0,
            "config-dojo-loader-catches": 0,
            "config-tlmSiblingOfDojo": 0,
            "dojo-amd-factory-scan": 0,
            "dojo-combo-api": 0,
            "dojo-config-api": 1,
            "dojo-config-require": 0,
            "dojo-debug-messages": 0,
            "dojo-dom-ready-api": 1,
            "dojo-firebug": 0,
            "dojo-guarantee-console": 1,
            "dojo-has-api": 1,
            "dojo-inject-api": 1,
            "dojo-loader": 1,
            "dojo-log-api": 0,
            "dojo-modulePaths": 0,
            "dojo-moduleUrl": 0,
            "dojo-publish-privates": 0,
            "dojo-requirejs-api": 0,
            "dojo-sniff": 1,
            "dojo-sync-loader": 0,
            "dojo-test-sniff": 0,
            "dojo-timeout-api": 0,
            "dojo-trace-api": 0,
            "dojo-undef-api": 0,
            "dojo-v1x-i18n-Api": 1,
            "dom": 1,
            "host-browser": 1,
            "extend-dojo": 1
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
                           "dojo/domReady", "dojo/on" ],
                customBase: true,
                boot: true
            },
            "lsmb/main": {
                include: [ "lsmb/DateTextBox",
                    "lsmb/Form",
                    "lsmb/Invoice",
                    "lsmb/InvoiceLine",
                    "lsmb/InvoiceLines",
                    "lsmb/MainContentPane",
                    "lsmb/MaximizeMinimize",
                    "lsmb/PrintButton",
                    "lsmb/PublishCheckBox",
                    "lsmb/PublishRadioButton",
                    "lsmb/PublishSelect",
                    "lsmb/SetupLoginButton",
                    "lsmb/SubscribeCheckBox",
                    "lsmb/SubscribeSelect",
                    "lsmb/SubscribeShowHide",
                    "lsmb/TabularForm"
                ]
            }
        }
    };
})();
