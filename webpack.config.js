/** @format */
/* eslint global-require:0, no-param-reassign:0, no-unused-vars:0 */
/* global getConfig */

const glob = require("glob");
const path = require("path");
const webpack = require("webpack");

const CopyWebpackPlugin = require("copy-webpack-plugin");
const DojoWebpackPlugin = require("dojo-webpack-plugin");
const { DuplicatesPlugin } = require("inspectpack/plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const MultipleThemesCompile = require("webpack-multiple-themes-compile");
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
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
    ],
    exclude: /node_modules/
};

// Used in css loader definition below and webpack-multiple-themes-compile plugin
const cssRules = [
    {
        loader: MiniCssExtractPlugin.loader,
        options: {
            hmr: !prodMode,
            publicPath: "js"
        }
    },
    {
        loader: "css-loader",
        options: {
            sourceMap: !prodMode,
            url: false
        }
    }
];

const css = {
    test: /\.css$/i,
    use: cssRules
};

const lessRules = [
    ...cssRules,
    {
        loader: "less-loader" // compiles Less to CSS
    }
];

const less = {
    test: /\.(less)$/,
    use: lessRules
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
    preHeader: "/* eslint-disable */",
    outputName: "css/[name].css",
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
    lessContent: ""
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

const themes = MultipleThemesCompile(multipleThemesCompileOptions);

// Generate entries from file pattern
const mapFilenamesToEntries = (pattern) =>
    glob.sync(pattern).reduce((entries, filename) => {
        const [, name] = filename.match(/([^/]+)\.css$/);
        return { ...entries, [name]: filename };
    }, {});

const lsmbCSS = mapFilenamesToEntries(path.resolve("UI/css/*.css"));

var pluginsProd = [
    new CleanWebpackPlugin(CleanWebpackPluginOptions),

    new webpack.HashedModuleIdsPlugin(), // so that file hashes don't change unexpectedly

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

    new HtmlWebpackPlugin({
        inject: false, // Tags are injected manually in the content below
        minify: false, // Adjust t/16-schema-upgrade-html.t if prodMode is used,
        filename: "ui-header.html",
        excludeChunks: [
            ...Object.keys(multipleThemesCompileOptions.themesConfig),
            ...Object.keys(lsmbCSS)
        ],
        templateContent: ({ htmlWebpackPlugin }) => `` +
            `<!-- prettier-disable -->\n` +
            `[%#\n` +
            `    # This helper should be included in files which will be served as\n` +
            `    # top-level responses (i.e. documents on their own); this includes\n` +
            `    # UI/login.html, UI/logout.html, UI/main.html and various UI/setup/ pages\n` +

            `    # Most LedgerSMB responses are handled by the 'xhr' Dojo module, which\n` +
            `    # *only* needs opening and closing BODY tags to be there (for now).\n` +
            `    #\n` +
            `    # Note: To keep some comments as is and control pre or post white space\n` +
            `    #       chomping, we make use of '+' or '-' beside the introducers in\n` +
            `    #       comments like this one.\n` +
            ` -%]\n` +
            `<!DOCTYPE html>\n` +
            `<html xmlns="http://www.w3.org/1999/xhtml">\n` +
            `<head>\n` +
            `    <title>[% title %]</title>\n` +
            `    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />\n` +
            `    [%+# HTML Snippet, for import only %]\n` +
            `    [%+#\n` +
            `        # source comment only!\n` +
            `        #\n` +
            `        # don't specify a title on the stylesheets: we want them to be\n` +
            `        # *persistent*\n` +
            `        # http://www.w3.org/TR/html401/present/styles.html#h-14.3.1\n` +
            `    %]\n` +
            `    ${htmlWebpackPlugin.tags.headTags}\n` +
            `    <link href="js/css/[% dojo_theme %].css" rel="stylesheet">\n` +
            `    [% IF form.stylesheet %]\n` +
            `    <link href="js/css/[% form.stylesheet %]" rel="stylesheet">\n` +
            `    [% ELSIF stylesheet %]\n` +
            `    <link href="js/css/[% stylesheet %]" rel="stylesheet">\n` +
            `    [% END %]\n` +
            `    [% FOREACH s = include_stylesheet %]\n` +
            `    <link href="js/css/[% s %]" rel="stylesheet">\n` +
            `    [% END %]\n` +
            `    [% IF warn_expire %]\n` +
            `    <script>\n` +
            `        window.alert("[% text('Warning:  Your password will expire in [_1]', pw_expires)%]");\n` +
            `    </script>\n` +
            `    [% END %]\n` +
            `    <script>\n` +
            `        var dojoConfig = {\n` +
            `            async: 1,\n` +
            `            locale: "[% USER.language.lower().replace('_','-') %]",\n` +
            `            packages: [{"name":"lsmb","location":"../lsmb"}]\n` +
            `        };\n` +
            `        var lsmbConfig = {\n` +
            `            [% IF USER.dateformat %]\n` +
            `            "dateformat": '[% USER.dateformat %]'\n` +
            `            [% END %]\n` +
            `        };\n` +
            `    </script>\n` +
            `    ${htmlWebpackPlugin.tags.bodyTags}\n` +
            `    <meta name="robots" content="noindex,nofollow" />\n` +
            `</head>\n` +
            `[% BLOCK end_html %]\n` +
            `</html>\n` +
            `[% END %]`
    }),

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
    minSize: 0,
    minChunks: 1,
    reuseExistingChunk: true,
    enforce: true
};

const optimizationList = {
    moduleIds: 'hashed',
    runtimeChunk: {
      name: 'manifest' // runtimeChunk: "multiple", /* Fails */
    },
    namedChunks: true, // Keep names to load only 1 theme
    splitChunks: !prodMode
        ? false
        : {
              chunks: "all",
              maxInitialRequests: Infinity,
              cacheGroups: {
                  main: {
                      test: /lsmb[\\/]main.+\.js/,
                      name: "main",
                      ...groupsOptions
                  },
                  // TODO: Can't we map those 4 following entries
                  claroTheme: {
                      ...themes.optimization.splitChunks.cacheGroups.claroTheme,
                      ...groupsOptions
                  },
                  nihiloTheme: {
                      ...themes.optimization.splitChunks.cacheGroups
                          .nihiloTheme,
                      ...groupsOptions
                  },
                  soriaTheme: {
                      ...themes.optimization.splitChunks.cacheGroups.soriaTheme,
                      ...groupsOptions
                  },
                  tundraTheme: {
                      ...themes.optimization.splitChunks.cacheGroups
                          .tundraTheme,
                      ...groupsOptions
                  },
                  node_modules: {
                      test: /[\\/]node_modules[\\/]/,
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
            sourceMap: !prodMode,
            terserOptions: {
                ecma: 6
            }
        }),
        new OptimizeCSSAssetsPlugin({
            cssProcessor: require('cssnano'),
            cssProcessorOptions: {
              discardComments: { removeAll: true },
              zindex: {
                disabled: true
              }
            },
            canPrint: true
          })
    ]
};

/* WEBPACK CONFIG */

const webpackConfigs = {
    context: path.join(__dirname, "UI"),

    // stats: 'verbose',

    entry: {
        main: "lsmb/main.js",
        ...lsmbCSS,
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
