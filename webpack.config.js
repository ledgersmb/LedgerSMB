/** @format */
/* eslint global-require:0, no-param-reassign:0, no-unused-vars:0 */
/* global getConfig */

const TARGET = process.env.npm_lifecycle_event;

if (TARGET !== 'readme') {
    const fs = require("fs");
    const glob = require("glob");
    const path = require("path");
    const webpack = require("webpack");

    const BundleAnalyzerPlugin = require("webpack-bundle-analyzer").BundleAnalyzerPlugin;
    const CompressionPlugin = require("compression-webpack-plugin");
    const CopyWebpackPlugin = require("copy-webpack-plugin");
    const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
    const DojoWebpackPlugin = require("dojo-webpack-plugin");
    const { DuplicatesPlugin } = require("inspectpack/plugin");
    const ESLintPlugin = require("eslint-webpack-plugin");
    const HtmlWebpackPlugin = require("html-webpack-plugin");
    const MiniCssExtractPlugin = require("mini-css-extract-plugin");
    //const ObsoleteWebpackPlugin = require("obsolete-webpack-plugin");
    const StylelintPlugin = require("stylelint-bare-webpack-plugin");
    const TerserPlugin = require("terser-webpack-plugin");
    const UnusedWebpackPlugin = require("unused-webpack-plugin");
    const { VueLoaderPlugin } = require("vue-loader");

    const { CleanWebpackPlugin } = require("clean-webpack-plugin"); // installed via npm

    const argv = require("yargs").argv;
    const prodMode =
        process.env.NODE_ENV === "production" ||
        argv.p ||
        argv.mode === "production";

    // Make sure all modules follow desired mode
    process.env.NODE_ENV = prodMode ? "production" : "development";
    const parallelJobs = process.env.CI || process.env.TRAVIS ? 2 : true;

    /* FUNCTIONS */

    var includedRequires = [
        "dijit/Dialog",
        "dijit/form/Button",
        "dijit/form/CheckBox",
        "dijit/form/ComboBox",
        "dijit/form/CurrencyTextBox",
        "dijit/form/MultiSelect",
        "dijit/form/NumberSpinner",
        "dijit/form/NumberTextBox",
        "dijit/form/RadioButton",
        "dijit/form/Select",
        "dijit/form/Textarea",
        "dijit/form/TextBox",
        "dijit/form/ToggleButton",
        "dijit/form/ValidationTextBox",
        "dijit/layout/BorderContainer",
        "dijit/layout/ContentPane",
        "dijit/layout/TabContainer",
        "dijit/Tooltip",
        "lsmb/ToggleIncludeButton"
    ];

    function findDataDojoTypes(fileName) {
        var content = "" + fs.readFileSync(fileName);
        // Return unique data-dojo-type refereces
        return (
            content.match(/(?<=['"]?data-dojo-type['"]?\s*=\s*")([^"]+)(?=")/gi) ||
            []
        ).filter((x, i, a) => a.indexOf(x) === i);
    }

    // Compute used data-dojo-type
    glob.sync("**/*.html", {
        ignore: ["lib/ui-header.html", "js/**", "js-src/{dojo,dijit,util}/**"],
        cwd: "UI"
    }).map(function (filename) {
        const requires = findDataDojoTypes("UI/" + filename);
        return includedRequires.push(...requires);
    });

    // Pull UI/js-src/lsmb
    includedRequires = includedRequires
        .concat(
            glob
                .sync("lsmb/**/!(webpack.loaderConfig|main).js", {
                    cwd: "UI/js-src/"
                })
                .map(function (file) {
                    return file.replace(/\.js$/, "");
                })
        )
        .filter((x, i, a) => a.indexOf(x) === i)
        .sort();

    /* LOADERS */

    const javascript = {
        test: /\.js$/,
        use: [
            {
                loader: "babel-loader",
                options: {
                    presets: ["@babel/preset-env"]
                }
            }
        ],
        exclude: file => {
            return /node_modules/.test(file) || /_scripts/.test(file);
        }
    };

    const vue = {
        test: /\.vue$/,
        loader: "vue-loader"
    };

    const css = {
        test: /\.css$/i,
        use: [ MiniCssExtractPlugin.loader, "css-loader"]
    };

    const images = {
        test: /\.(png|jpe?g|gif)$/i,
        type: 'asset'
    };

    const html = {
        test: /\.html$/,
        use: [
            {
                loader: "ejs-loader",
                options: {
                    esModule: false
                }
            }
        ]
    };

    const svg = {
        test: /\.svg$/,
        type: 'asset/resource'
    };

    /* PLUGINS */

    const CleanWebpackPluginOptions = {
        dry: false,
        verbose: false
    }; // delete all files in the js directory without deleting this folder

    const ESLintPluginOptions = {
        files: "**/*.js",
        emitError: prodMode,
        emitWarning: !prodMode
    };

    const StylelintPluginOptions = {
        files: "**/*.css"
    };

    // Copy non-packed resources needed by the app to the release directory
    const CopyWebpackPluginOptions = {
        patterns: [
            { context: "../node_modules", from: "dijit/icons/**/*", to: "." },
            { context: "../node_modules", from: "dijit/nls/**/*", to: "." },
            { context: "../node_modules", from: "dojo/nls/**/*", to: "." },
            { context: "../node_modules", from: "dojo/resources/**/*", to: "." }
        ],
        options: {
            concurrency: 100
        }
    };

    const DojoWebpackPluginOptions = {
        loaderConfig: require("./UI/js-src/lsmb/webpack.loaderConfig.js"),
        environment: { dojoRoot: "UI/js" }, // used at run time for non-packed resources (e.g. blank.gif)
        buildEnvironment: { dojoRoot: "node_modules" }, // used at build time
        locales: ["en"],
        noConsole: true
    };

    // dojo/domReady (only works if the DOM is ready when invoked)
    const NormalModuleReplacementPluginOptionsDomReady = function (data) {
        const match = /^dojo\/domReady!(.*)$/.exec(data.request);
        /* eslint-disable-next-line no-param-reassign */
        data.request = "dojo/loaderProxy?loader=dojo/domReady!" + match[1];
    };

    const NormalModuleReplacementPluginOptionsSVG = function (data) {
        var match = /^svg!(.*)$/.exec(data.request);
        /* eslint-disable-next-line no-param-reassign */
        data.request =
            "dojo/loaderProxy?loader=svg&deps=dojo/text%21" +
            match[1] +
            "!" +
            match[1];
    };

    const UnusedWebpackPluginOptions = {
        // Source directories
        directories: ["js-src/lsmb"],
        // Exclude patterns
        exclude: ["*.test.js"],
        // Root directory (optional)
        root: path.join(__dirname, "UI")
    };

    // Generate entries from file pattern
    const mapFilenamesToEntries = (pattern) =>
        glob.sync(pattern).reduce((entries, filename) => {
            const [, name] = filename.match(/([^/]+)\.css$/);
            return { ...entries, [name]: filename };
        }, {});

    const _dijitThemes = "+(claro|nihilo|soria|tundra)";
    const lsmbCSS = {
        ...mapFilenamesToEntries(path.resolve("UI/css/*.css")),
        ...mapFilenamesToEntries(
            path.resolve(
                "node_modules/dijit/themes/" +
                    _dijitThemes +
                    "/" +
                    _dijitThemes +
                    ".css"
            )
        )
    };

    var pluginsProd = [
        new VueLoaderPlugin(),
        // Clean UI/js before building
        new CleanWebpackPlugin(CleanWebpackPluginOptions),

        // Lint the sources
        new ESLintPlugin(ESLintPluginOptions),
        new StylelintPlugin(StylelintPluginOptions),

        // Add Dojo
        new DojoWebpackPlugin(DojoWebpackPluginOptions),

        // dojo-webpack-plugin doesn't support domReady!
        new webpack.NormalModuleReplacementPlugin(
            /^dojo\/domReady!/,
            NormalModuleReplacementPluginOptionsDomReady
        ),

        new webpack.NormalModuleReplacementPlugin(/^dojo\/text!/, function (data) {
            /* eslint-disable-next-line no-param-reassign */
            data.request = data.request.replace(/^dojo\/text!/, "!!raw-loader!");
        }),

        // Copy a few Dojo ressources
        new CopyWebpackPlugin(CopyWebpackPluginOptions),

        // Handle SVG
        new webpack.NormalModuleReplacementPlugin(
            /^svg!/,
            NormalModuleReplacementPluginOptionsSVG
        ),

        // Handle CSS
        new MiniCssExtractPlugin({
            experimentalUseImportModule: false,
            filename: "css/[name].css",
            chunkFilename: "css/[id].css"
        }),

        // Handle HTML
        new HtmlWebpackPlugin({
            inject: false, // Tags are injected manually in the content below
            minify: false, // Adjust t/16-schema-upgrade-html.t if prodMode is used,
            filename: "ui-header.html",
            mode: prodMode ? "production" : "development",
            excludeChunks: [...Object.keys(lsmbCSS)],
            template: "lib/ui-header.html"
        }),

        // Add obsoleted browser warning on application start
        // Not yet webpack5 ready
    /*
        new ObsoleteWebpackPlugin({
            name: "obsolete"
        }),
    */
        // Analyze the generated JS code. Use `npm run analyzer` to view
        new BundleAnalyzerPlugin({
            analyzerHost: "0.0.0.0",
            analyzerMode: prodMode ? "disabled" : "json",
            openAnalyzer: false,
            generateStatsFile: !prodMode,
            statsFilename: "../../logs/stats.json",
            reportFilename: "../../logs/report.json"
        }),

        // Warn on duplication of code
        new DuplicatesPlugin({
            // Emit compilation warning or error? (Default: `false`)
            emitErrors: false,
            // Display full duplicates information? (Default: `false`)
            verbose: true
        }),

        // Generate GZ versions of compiled code to sppedup download
        new CompressionPlugin({
            filename: "[path][base].gz",
            algorithm: "gzip",
            test: /\.js$|\.css$|\.html$/,
            threshold: 10240,
            minRatio: 0.8
        }),

    ];

    var pluginsDev = [
        ...pluginsProd,

        new UnusedWebpackPlugin(UnusedWebpackPluginOptions)
    ];

    var pluginsList = prodMode ? pluginsProd : pluginsDev;

    /* OPTIMIZATIONS */

    const optimizationList = {
        chunkIds: "named", // Keep names to load only 1 theme
        emitOnErrors: false,
        minimize: prodMode,
        minimizer: [
            new TerserPlugin({
                parallel: parallelJobs
            }),
            new CssMinimizerPlugin({
                parallel: parallelJobs
            })
        ],
        moduleIds: 'deterministic',
        runtimeChunk: "multiple",
        splitChunks: {
            cacheGroups: {
                node_modules: {
                    test(module) {
                        // `module.resource` contains the absolute path of the file on disk.
                        // Note the usage of `path.sep` instead of / or \, for cross-platform compatibility.
                        return (
                            module.resource &&
                            !module.resource.endsWith(".css") &&
                            module.resource.includes(
                                `${path.sep}node_modules${path.sep}`
                            )
                        );
                    },
                    name(module) {
                        const packageName = module.context.match(
                            /[\\/]node_modules[\\/](.*?)([\\/]|$)/
                        )[1];
                        return `npm.${packageName.replace("@", "")}`;
                    },
                    chunks: "all"
                }
            }
        }
    };

    /* WEBPACK CONFIG */

    const webpackConfigs = {
        context: path.join(__dirname, "UI"),

        entry: {
            main: {
                filename: "lsmb/main.js",
                import: "lsmb/main",
                dependOn: 'shared'
            },
            shared: [ ...includedRequires ],
            ...lsmbCSS
        },

        output: {
            path: path.join(__dirname, "UI/js"), // js path
            publicPath: "js/", // images path
            pathinfo: !prodMode, // keep source references?
            filename: "_scripts/[name].[contenthash].js",
            chunkFilename: "_scripts/[name].[contenthash].js"
        },

        module: {
            rules: [vue, javascript, css, images, svg, html]
        },

        plugins: pluginsList,

        resolve: {
            alias: {
//                "vue$": "vue/dist/vue.esm.js"
                "vue$": "vue/dist/vue.esm-bundler.js"
            },
            extensions: [ ".js", ".vue" ],
            fallback: {
                buffer: require.resolve("buffer/"),
                path: require.resolve("path-browserify")
            }
        },

        resolveLoader: {
            modules: ["node_modules"]
        },

        mode: process.env.NODE_ENV,

        optimization: optimizationList,

        performance: { hints: prodMode ? false : "warning" },

        devtool: prodMode ? "hidden-source-map" : "source-map"
    };

    module.exports = webpackConfigs;
}
else{
    const { merge } = require("webpack-merge");

    /* Include Markdown compiling for README.md */
    const WebpackCompileMarkdown = require("./UI/js-src/webpack-compile-markdown.js");
    module.exports = merge({ entry: {}}, WebpackCompileMarkdown);
}
