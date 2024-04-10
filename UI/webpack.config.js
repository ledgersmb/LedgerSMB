/** @format */
/* eslint global-require:0, no-param-reassign:0, no-unused-vars:0 */
/* global getConfig */

const TARGET = process.env.npm_lifecycle_event;

if (TARGET !== "readme") {
    const fs = require("fs"),
        glob = require("glob"),
        path = require("path"),
        webpack = require("webpack"),
        BundleAnalyzerPlugin =
            require("webpack-bundle-analyzer").BundleAnalyzerPlugin,
        { CleanWebpackPlugin } = require("clean-webpack-plugin"), // installed via npm
        CompressionPlugin = require("compression-webpack-plugin"),
        CopyWebpackPlugin = require("copy-webpack-plugin"),
        CssMinimizerPlugin = require("css-minimizer-webpack-plugin"),
        DojoWebpackPlugin = require("dojo-webpack-plugin"),
        HtmlWebpackPlugin = require("html-webpack-plugin"),
        MiniCssExtractPlugin = require("mini-css-extract-plugin"),
        StylelintPlugin = require("stylelint-webpack-plugin"),
        UnusedWebpackPlugin = require("unused-webpack-plugin"),
        VirtualModulesPlugin = require("webpack-virtual-modules"),
        { VueLoaderPlugin } = require("vue-loader"),
    // eslint-disable-next-line
        { WebpackDeduplicationPlugin } = require("webpack-deduplication-plugin"),
        argv = require("yargs").argv,
        prodMode =
        process.env.NODE_ENV === "production" ||
        argv.p ||
            argv.mode === "production",
        parallelJobs = process.env.CI ? 2 : true;

    // Make sure all modules follow desired mode
    process.env.NODE_ENV = prodMode ? "production" : "development";

    /* FUNCTIONS */
    var includedRequires = [];

    function findDataDojoTypes(fileName) {
        var content = "" + fs.readFileSync(fileName);
        // Return unique data-dojo-type refereces
        return (
            content.match(
                /(?<=['"]?data-dojo-type['"]?\s*=\s*")([^"]+)(?=")/gi
            ) || []
        ).filter((x, i, a) => a.indexOf(x) === i);
    }

    function getPOFilenames(_path, extension) {
        return fs
            .readdirSync(_path)
            .filter(
                (item) =>
                    fs.statSync(path.join(_path, item)).isFile() &&
                    (extension === undefined ||
                        path.extname(item) === extension)
            )
            .map((item) => path.basename(item, extension))
            .sort();
    }

    function globCssEntries(globPath) {
        const files = glob.sync(globPath);
        let entries = {};

        for (var i = 0; i < files.length; i++) {
            const entry = files[i],
                dirName = path.dirname(entry).replace(/\.\/css\/?/, ""),
                keyName =
                    (dirName ? dirName + "/" : "") +
                    path.basename(entry, path.extname(entry));
            entries[keyName] = path.join(__dirname, entry);
        }
        return entries;
    }

    // Compute used data-dojo-type
    glob.sync("**/*.html", {
        ignore: ["lib/ui-header.html", "js/**", "node_modules/**"]
        // cwd: "."
    }).map(function (filename) {
        const requires = findDataDojoTypes(filename);
        return includedRequires.push(...requires);
    });

    glob.sync("../old/bin/*.pl").map(function (filename) {
        const requires = findDataDojoTypes(filename);
        return includedRequires.push(...requires);
    });

    // Pull js-src/lsmb
    includedRequires = includedRequires
        .concat(
            glob
                .sync(
                    "{js-src/lsmb/**/!(webpack.loaderConfig|main).js,src/*.js,src/elements/*.js}",
                    {
                        // cwd: "."
                    }
                )
                .map(function (file) {
                    return file.replace(/\.js$/, "").replace(/js-src\//, "");
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
        exclude: (file) => {
            return /node_modules/.test(file) || /_scripts/.test(file);
        }
        },
        vue = {
        test: /\.vue$/,
        loader: "vue-loader",
        options: {
            compilerOptions: {
                isCustomElement: (tag) => tag.startsWith("lsmb-")
            }
        }
        },
        css = {
        test: /\.css$/i,
        use: [MiniCssExtractPlugin.loader, "css-loader"]
        },
        images = {
        test: /\.(png|jpe?g|gif)$/i,
        type: "asset"
        },
        html = {
        test: /\.html$/,
        use: [
            {
                loader: "ejs-loader",
                options: {
                    esModule: false
                }
            }
        ]
        },
        svg = {
        test: /\.svg$/,
        type: "asset/resource"
        },
    /* PLUGINS */

        CleanWebpackPluginOptions = {
        dry: false,
        verbose: false
        }, // delete all files in the js directory without deleting this folder
        StylelintPluginOptions = {
        files: "**/*.css"
        },
    // Copy non-packed resources needed by the app to the release directory
        CopyWebpackPluginOptions = {
        patterns: [
            { context: "node_modules", from: "dijit/icons/**/*", to: "." },
            { context: "node_modules", from: "dijit/nls/**/*", to: "." },
            { context: "node_modules", from: "dojo/nls/**/*", to: "." },
                {
                    context: "node_modules",
                    from: "dojo/resources/**/*",
                    to: "."
                }
        ],
        options: {
            concurrency: 100
        }
        },
        DojoWebpackPluginOptions = {
        loaderConfig: require("./js-src/lsmb/webpack.loaderConfig.js"),
        environment: { dojoRoot: "js" }, // used at run time for non-packed resources (e.g. blank.gif)
        buildEnvironment: { dojoRoot: "node_modules" }, // used at build time
        locales: getPOFilenames("src/locales", ".json"),
        noConsole: true
        },
    // dojo/domReady (only works if the DOM is ready when invoked)
        NormalModuleReplacementPluginOptionsDomReady = function (data) {
        const match = /^dojo\/domReady!(.*)$/.exec(data.request);

        data.request = "dojo/loaderProxy?loader=dojo/domReady!" + match[1];
        },
        NormalModuleReplacementPluginOptionsSVG = function (data) {
            var match = /^svg!(.*)$/.exec(data.request);

        data.request =
            "dojo/loaderProxy?loader=svg&deps=dojo/text%21" +
            match[1] +
            "!" +
            match[1];
        },
        UnusedWebpackPluginOptions = {
        // Source directories
        directories: [
            path.join(__dirname, "js-src/lsmb"),
            path.join(__dirname, "src")
        ],
        // Exclude patterns
        exclude: ["*.test.js", "webpack.loaderConfig.js"],
        // Root directory (optional)
        root: __dirname
        },
    // Generate entries from file pattern
        mapFilenamesToEntries = (pattern) =>
        glob.sync(pattern).reduce((entries, filename) => {
            const [, name] = filename.match(/([^/]+)\.css$/);
            return { ...entries, [name]: filename };
            }, {}),
        _dijitThemes = "+(claro|nihilo|soria|tundra)",
        lsmbCSS = {
        ...mapFilenamesToEntries(path.resolve("css/*.css")),
        ...mapFilenamesToEntries(
            path.resolve(
                "node_modules/dijit/themes/" +
                    _dijitThemes +
                    "/" +
                    _dijitThemes +
                    ".css"
            )
        )
        },
    // Compile bootstrap module as a virtual one
        VirtualModulesPluginOptions = {
        "./bootstrap.js":
            `/* eslint-disable */\n` +
            `define(["dojo/parser","dojo/ready","` +
            includedRequires.join('","') +
            `"], function(parser, ready) {\n` +
            `    ready(function() {\n` +
            `    });\n` +
            `    return {};\n` +
            `});`
    };

    // eslint-disable-next-line one-var
    var pluginsCommon = [
        // Lint the sources
        new StylelintPlugin(StylelintPluginOptions),

        // Add Vue
        new VueLoaderPlugin(),

        // Add Dojo
        new DojoWebpackPlugin(DojoWebpackPluginOptions),

        // dojo-webpack-plugin doesn't support domReady!
        new webpack.NormalModuleReplacementPlugin(
            /^dojo\/domReady!/,
            NormalModuleReplacementPluginOptionsDomReady
        ),

        new webpack.NormalModuleReplacementPlugin(/^dojo\/text!/, function (
            data
        ) {
            data.request = data.request.replace(
                /^dojo\/text!/,
                "!!raw-loader!"
            );
        }),

        new VirtualModulesPlugin(VirtualModulesPluginOptions),

        // Copy a few Dojo ressources
        new CopyWebpackPlugin(CopyWebpackPluginOptions),

        // Handle SVG
        new webpack.NormalModuleReplacementPlugin(
            /^svg!/,
            NormalModuleReplacementPluginOptionsSVG
        ),

        // Handle CSS
        new MiniCssExtractPlugin({
            filename: "css/[name].css",
            chunkFilename: "css/[id].css"
        }),

        // Handle HTML
        new HtmlWebpackPlugin({
                inject: "body", // Tags are injected manually in the content below
            minify: false, // Adjust t/16-schema-upgrade-html.t if prodMode is used,
            filename: "ui-header.html",
            mode: prodMode ? "production" : "development",
                excludeChunks: [
                    ...Object.keys(lsmbCSS),
                    ...Object.keys(globCssEntries("./css/**/*.css"))
                ],
            template: "lib/ui-header.html"
        }),

        // Analyze the generated JS code. Use `npm run analyzer` to view
        new BundleAnalyzerPlugin({
            analyzerHost: "0.0.0.0",
            analyzerMode: prodMode ? "disabled" : "json",
            openAnalyzer: false,
            generateStatsFile: !prodMode,
            statsFilename: "../../logs/stats.json",
            reportFilename: "../../logs/report.json"
        }),

        new WebpackDeduplicationPlugin({}),

        // Generate GZ versions of compiled code to sppedup download
        new CompressionPlugin({
            filename: "[path][base].gz",
            algorithm: "gzip",
            test: /\.js$|\.css$|\.html$/,
            threshold: 10240,
            minRatio: 0.8
        }),

        // Statics from build.
        new webpack.DefinePlugin({
            "process.env.VUE_APP_I18N_LOCALE": "en",
            "process.env.VUE_APP_I18N_FALLBACK_LOCALE": "en",
            __SUPPORTED_LOCALES: getPOFilenames("../locale/po", ".po").map(
                function (po) {
                    return "'" + po + "'";
                }
            ),
            __VUE_PROD_DEVTOOLS__: true
        })
        ],
        pluginsProd = [
        ...pluginsCommon,

        // Statics from build.
        new webpack.DefinePlugin({
            __VUE_PROD_DEVTOOLS__: true
        })
        ],
        pluginsDev = [
        ...pluginsCommon,

        new UnusedWebpackPlugin(UnusedWebpackPluginOptions),

        new webpack.DefinePlugin({
            __VUE_I18N_FULL_INSTALL__: JSON.stringify(true),
            __INTLIFY_PROD_DEVTOOLS__: JSON.stringify(false),
            __VUE_I18N_LEGACY_API__: JSON.stringify(false),
            __VUE_OPTIONS_API__: true,
            __VUE_PROD_DEVTOOLS__: true
        })
        ],
        pluginsList = prodMode
        ? [
              // Clean js before building (must be first)
              new CleanWebpackPlugin(CleanWebpackPluginOptions),
              ...pluginsProd
          ]
        : pluginsDev;

    /* OPTIMIZATIONS */

    // eslint-disable-next-line one-var
    const optimizationList = {
        chunkIds: "named", // Keep names to load only 1 theme
        emitOnErrors: false,
        minimize: prodMode,
        minimizer: [
            `...`,
            new CssMinimizerPlugin({
                parallel: parallelJobs
            })
        ],
        moduleIds: "deterministic",
        runtimeChunk: "multiple",
        splitChunks: {
            cacheGroups: {
                    nodeModules: {
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
        },
    /* WEBPACK CONFIG */

        webpackConfigs = {
        experiments: {
            topLevelAwait: true
        },

        context: __dirname,

        entry: {
            bootstrap: "./bootstrap.js", // Virtual file
            ...lsmbCSS,
            ...globCssEntries("./css/**/*.css")
        },

        output: {
            path: path.join(__dirname, "js"), // js path
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
                vue$: "vue/dist/vue.cjs.js",
                "vue-router": "vue-router/dist/vue-router.cjs.js",
                pinia$: "pinia/dist/pinia.cjs",
                "vue-i18n": "vue-i18n/dist/vue-i18n.cjs",
                "@pinia": path.join(__dirname, "node_modules/@pinia"), // Fix eslint importer
                "@": path.join(__dirname, "src/")
            },
            extensions: [".js", ".vue"],
            fallback: {
                path: require.resolve("path-browserify")
            }
        },

        resolveLoader: {
            modules: ["node_modules"]
        },

        mode: process.env.NODE_ENV,

        optimization: optimizationList,

        performance: {
            hints: prodMode ? false : "warning",
            maxAssetSize: prodMode ? 250000 /* the default */ : 10000000,
                maxEntrypointSize: prodMode
                    ? 250000 /* the default */
                    : 10000000
        },

        devtool: prodMode ? "hidden-source-map" : "source-map",

        devServer: {
            allowedHosts: "all", // Replace with docker parent and localhost
            client: {
                logging: "verbose",
                overlay: {
                    errors: true,
                    warnings: false
                },
                progress: true
            },
            compress: true,
            devMiddleware: {
                index: false,
                serverSideRender: true,
                writeToDisk: true // Required for Perl TT
            },
            hot: true,
            host: "0.0.0.0",
            liveReload: true,
            port: 9000,
            proxy: [
                {
                    context: ["/*.pl"],
                    target: "http://proxy"
                },
                {
                    context: ["/erp/api"],
                    target: "http://proxy"
                },
                {
                    context: ["/app/*.pl"],
                    target: "http://proxy",
                    pathRewrite: { "^/app": "" }
                },
                {
                    context: ["/app/erp/api"],
                    target: "http://proxy",
                    pathRewrite: { "^/app": "" }
                }
            ],
            static: [
                {
                    directory: __dirname,
                        publicPath: "/"
                },
                {
                    directory: __dirname,
                        publicPath: "/app"
                }
            ],
            watchFiles: [
                "webpack.config.js",
                "**/*.{html,css,gif,jpg,png,svg,json}",
                "js-src/**/*.js",
                "src/**/*.{js,vue}"
            ]
        },

        target: "web"
    };

    module.exports = webpackConfigs;
} else {
    const { merge } = require("webpack-merge");

    /* Include Markdown compiling for README.md */
    const WebpackCompileMarkdown = require("./js-src/webpack-compile-markdown.js");
    module.exports = merge({ entry: {} }, WebpackCompileMarkdown);
}
