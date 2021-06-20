/** @format */
/* eslint global-require:0, no-param-reassign:0, no-unused-vars:0 */
/* global getConfig */

const fs = require("fs");
const glob = require("glob");
const path = require("path");
const webpack = require("webpack");
const { merge } = require("webpack-merge");

const CopyWebpackPlugin = require("copy-webpack-plugin");
const DojoWebpackPlugin = require("dojo-webpack-plugin");
const { DuplicatesPlugin } = require("inspectpack/plugin");
const ESLintPlugin = require("eslint-webpack-plugin");
const ExtractCssChunks = require("extract-css-chunks-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const ObsoleteWebpackPlugin = require("obsolete-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const StylelintPlugin = require("stylelint-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const UnusedWebpackPlugin = require("unused-webpack-plugin");
const VirtualModulePlugin = require("virtual-module-webpack-plugin");

const { CleanWebpackPlugin } = require("clean-webpack-plugin"); // installed via npm

const argv = require("yargs").argv;
const prodMode =
    process.env.NODE_ENV === "production" ||
    argv.p ||
    argv.mode === "production";

// Make sure all modules follow desired mode
process.env.NODE_ENV = prodMode ? "production" : "development";

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
    ignore: [
        "lib/ui-header.html",
        "js/**",
        "js-src/dojo/**",
        "js-src/dijit/**",
        "js-src/util/**"
    ],
    cwd: "UI"
}).map(function (filename) {
    const requires = findDataDojoTypes("UI/" + filename);
    return includedRequires.push(...requires);
});

// Pull UI/js-src/lsmb
includedRequires = includedRequires
    .concat(
        glob
            .sync("lsmb/**/!(bootstrap|webpack.loaderConfig).js", {
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
    enforce: "pre",
    test: /\.js$/,
    use: [
        {
            loader: "babel-loader",
            options: {
                presets: ["@babel/preset-env"]
            }
        }
    ],
    exclude: /node_modules/
};

const css = {
    test: /\.css$/i,
    use: [
        {
            loader: ExtractCssChunks.loader,
            options: {
                hmr: !prodMode
            }
        },
        "css-loader"
    ]
};

const images = {
    test: /\.(png|jpe?g|gif)$/i,
    use: [
        {
            loader: "url-loader",
            options: {
                limit: 8192
            }
        }
    ]
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
    loader: "file-loader"
};

/* PLUGINS */

const CleanWebpackPluginOptions = {
    dry: false,
    verbose: false
}; // delete all files in the js directory without deleting this folder

const ESLintPluginOptions = {
    files: "**/!(bootstrap|lsmb.profile).js",
    emitError: prodMode,
    emitWarning: !prodMode,
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

// Compile bootstrap module as a virtual one
const VirtualModulePluginOptions = {
    moduleName: "js-src/lsmb/bootstrap.js",
    contents: `/* eslint-disable */
        define(["dojo/parser","dojo/ready","${includedRequires.join(
            '","'
        )}"], function(parser, ready) {
            ready(function() {
            });
            return {};
        });`
};

// console.log(VirtualModulePluginOptions.contents);

var pluginsProd = [
    new CleanWebpackPlugin(CleanWebpackPluginOptions),

    new webpack.HashedModuleIdsPlugin(), // so that file hashes don't change unexpectedly

    new VirtualModulePlugin(VirtualModulePluginOptions),

    new ESLintPlugin(ESLintPluginOptions),
    new StylelintPlugin(StylelintPluginOptions),

    new DojoWebpackPlugin(DojoWebpackPluginOptions),

    new webpack.NormalModuleReplacementPlugin(/^dojo\/text!/, function (data) {
        /* eslint-disable-next-line no-param-reassign */
        data.request = data.request.replace(/^dojo\/text!/, "!!raw-loader!");
    }),

    new CopyWebpackPlugin(CopyWebpackPluginOptions),

    new webpack.NormalModuleReplacementPlugin(
        /^dojo\/domReady!/,
        NormalModuleReplacementPluginOptionsDomReady
    ),

    new webpack.NormalModuleReplacementPlugin(
        /^svg!/,
        NormalModuleReplacementPluginOptionsSVG
    ),

    new ExtractCssChunks({
        filename: prodMode ? "css/[name].[contenthash].css" : "css/[name].css",
        chunkFilename: "css/[id].css",
        moduleFilename: ({ name }) => `${name.replace("js/", "js/css/")}.css`
        // publicPath: "js"
    }),

    new HtmlWebpackPlugin({
        inject: false, // Tags are injected manually in the content below
        minify: false, // Adjust t/16-schema-upgrade-html.t if prodMode is used,
        filename: "ui-header.html",
        mode: prodMode ? "production" : "development",
        excludeChunks: [...Object.keys(lsmbCSS)],
        template: "lib/ui-header.html"
    }),

    new ObsoleteWebpackPlugin({
        name: "obsolete"
    })
];

var pluginsDev = [
    ...pluginsProd,

    new UnusedWebpackPlugin(UnusedWebpackPluginOptions),

    new DuplicatesPlugin({
        // Emit compilation warning or error? (Default: `false`)
        emitErrors: false,
        // Display full duplicates information? (Default: `false`)
        verbose: false
    })
];

var pluginsList = prodMode ? pluginsProd : pluginsDev;

/* OPTIMIZATIONS */

const groupsOptions = {
    chunks: "all",
    reuseExistingChunk: true,
    enforce: true
};

const optimizationList = {
    moduleIds: "hashed",
    runtimeChunk: {
        name: "manifest" // runtimeChunk: "multiple", // Fails
    },
    namedChunks: true, // Keep names to load only 1 theme
    noEmitOnErrors: true,
    splitChunks: !prodMode
        ? false
        : {
              chunks(chunk) {
                  // exclude dijit themes
                  return !chunk.name.match(/(claro|nihilo|soria|tundra)/);
              },
              maxInitialRequests: Infinity,
              cacheGroups: {
                  node_modules: {
                      test(module, chunks) {
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
                      priority: 2,
                      ...groupsOptions
                  }
              }
          },
    minimize: prodMode,
    minimizer: [
        new TerserPlugin({
            parallel: process.env.CIRCLECI || process.env.TRAVIS ? 2 : true,
            sourceMap: !prodMode
        }),
        new OptimizeCSSAssetsPlugin({
            cssProcessorOptions: {
                discardComments: { removeAll: true },
                zindex: {
                    disabled: true // Don't touch zindex
                }
            },
            canPrint: true
        })
    ]
};

/* WEBPACK CONFIG */

const webpackConfigs = {
    context: path.join(__dirname, "UI"),

    entry: {
        bootstrap: "js-src/lsmb/bootstrap.js", // Virtual file
        ...lsmbCSS
    },

    output: {
        path: path.resolve("UI/js"), // js path
        publicPath: "js/", // images path
        pathinfo: !prodMode, // keep source references?
        filename: "_scripts/[name].[contenthash].js",
        chunkFilename: "_scripts/[name].[contenthash].js"
    },

    module: {
        rules: [javascript, css, images, svg, html]
    },

    plugins: pluginsList,

    resolve: {
        extensions: [".js"],
        modules: ["node_modules"]
    },

    resolveLoader: {
        modules: ["node_modules"]
    },

    mode: process.env.NODE_ENV,

    optimization: optimizationList,

    performance: { hints: prodMode ? false : "warning" },

    devtool: prodMode ? undefined : "source-map"
};

/* Include Markdown compiling for README.md */
const WebpackCompileMarkdown = require("./UI/js-src/webpack-compile-markdown.js");

/* eslint-disable-next-line no-unused-vars */
module.exports = (env) => {
    return merge(webpackConfigs, WebpackCompileMarkdown);
};
