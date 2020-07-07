/** @format */
/* eslint global-require:0, no-param-reassign:0, no-unused-vars:0 */
/* global getConfig */

const path = require("path");
const webpack = require("webpack");

const CopyWebpackPlugin = require("copy-webpack-plugin");
const DojoWebpackPlugin = require("dojo-webpack-plugin");
const { DuplicatesPlugin } = require("inspectpack/plugin");
const MultipleThemesCompile = require("webpack-multiple-themes-compile");
const StylelintPlugin = require("stylelint-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const UnusedWebpackPlugin = require("unused-webpack-plugin");

const { CleanWebpackPlugin } = require("clean-webpack-plugin"); // installed via npm

const argv = require("yargs").argv;
const prodMode =
    process.env.NODE_ENV === "production" ||
    argv.p ||
    argv.mode === "production";

// Make sure all modules follow desired mode
process.env.NODE_ENV = prodMode ? "production" : "development";

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
        },
        {
            loader: "eslint-loader",
            options: {
                configFile: ".eslintrc",
                failOnError: true
            }
        }
    ]
};

// Used in css loader definition below and webpack-multiple-themes-compile plugin
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
    loader: "html-loader"
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

const multipleThemesCompileOptions = {
    cwd: "UI",
    cacheDir: "js",
    preHeader: "/* stylelint-disable */",
    outputName: "/dijit/themes/[name]/[name].css",
    themesConfig: {
        claro: {
            dojo_theme: "claro",
            import: ["../../node_modules/dijit/themes/claro/claro.css"]
        },
        nihilo: {
            dojo_theme: "nihilo",
            import: ["../../node_modules/dijit/themes/nihilo/nihilo.css"]
        },
        soria: {
            dojo_theme: "soria",
            import: ["../../node_modules/dijit/themes/soria/soria.css"]
        },
        tundra: {
            dojo_theme: "tundra",
            import: ["../../node_modules/dijit/themes/tundra/tundra.css"]
        }
    },
    lessContent: "body{dojo_theme:@dojo_theme}"
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

const NormalModuleReplacementPluginOptionsCSS = function (data) {
    data.request = data.request.replace(
        /^css!/,
        "!style-loader!css-loader!less-loader!"
    );
};

const UnusedWebpackPluginOptions = {
    // Source directories
    directories: ["js-src/lsmb"],
    // Exclude patterns
    exclude: ["*.test.js"],
    // Root directory (optional)
    root: path.join(__dirname, "UI")
};

const devServerOptions = {
    contentBase: "js",
    compress: true,
    port: 6969,
    stats: "errors-only",
    open: true,
    hot: true,
    openPage: ""
};

var pluginsProd = [
    new CleanWebpackPlugin(CleanWebpackPluginOptions),

    new webpack.DefinePlugin({
        VERSION: JSON.stringify(require("./package.json").version)
    }),

    // new webpack.HashedModuleIdsPlugin(webpack.HashedModuleIdsPluginOptions),
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

    new webpack.NormalModuleReplacementPlugin(
        /^css!/,
        NormalModuleReplacementPluginOptionsCSS
    )
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

const themes = MultipleThemesCompile(multipleThemesCompileOptions);

/* OPTIMIZATIONS */

const optimizationList = {
    /*
      runtimeChunk: {
        name: 'runtime',
      },
      */
    namedModules: false,
    splitChunks: !prodMode
        ? false
        : {
              chunks: "all",
              maxInitialRequests: Infinity,
              minSize: 0,
              cacheGroups: {
                  /*
              vendor: {
                 // That should be empty for Dojo?
                 test: /[\\/]node_modules[\\/]/,
                 name(module) {
                    // get the name. E.g. node_modules/packageName/not/this/part.js
                    // or node_modules/packageName
                    const packageName = module.context.match(
                       /[\\/]node_modules[\\/](.*?)([\\/]|$)/
                    )[1];

                    // npm package names are URL-safe, but some servers don't like @ symbols
                    return `npm.${packageName.replace("@", "")}`;
                 }
              },
              */
                  ...themes.optimization.splitChunks.cacheGroups
              }
          },
    minimize: prodMode,
    minimizer: !prodMode
        ? []
        : [
              new TerserPlugin({
                  parallel: process.env.CIRCLECI || process.env.TRAVIS ? 2 : true,
                  sourceMap: !prodMode,
                  terserOptions: {
                      ecma: 6
                  }
              })
          ]
};

/* WEBPACK CONFIG */

const webpackConfigs = {
    context: path.join(__dirname, "UI"),

    // stats: 'verbose',

    entry: {
        "lsmb/main": "lsmb/main.js",
        ...themes.entry
    },

    output: {
        path: path.resolve("UI/js"), // js path
        publicPath: "js/", // images path
        pathinfo: !prodMode, // keep source references?
        filename: "[name].js",
        chunkFilename: "[name].[chunkhash].js"
    },

    module: {
        rules: [javascript, images, svg, html, ...themes.module.rules]
    },

    plugins: [...pluginsList, ...themes.plugins],

    resolve: {
        extensions: [".js"],
        modules: ["node_modules"]
    },

    resolveLoader: {
        modules: ["node_modules"]
    },

    mode: process.env.NODE_ENV,

    optimization: optimizationList,

    performance: { hints: prodMode ? false : "warning" }
};

/* eslint-disable-next-line no-unused-vars */
module.exports = (env) => {
    return webpackConfigs;
};
