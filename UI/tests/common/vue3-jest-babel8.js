/** @format */

const crypto = require("crypto");
const { parse, compileTemplate, compileScript } = require("@vue/compiler-sfc");
const { transformSync } = require("@babel/core");
const babelJest = require("babel-jest").default;

const typescriptTransformer = require("@vue/vue3-jest/lib/transformers/typescript");
const coffeescriptTransformer = require("@vue/vue3-jest/lib/transformers/coffee");
const processStyle = require("@vue/vue3-jest/lib/process-style");
const processCustomBlocks = require("@vue/vue3-jest/lib/process-custom-blocks");
const {
    getTypeScriptConfig,
    getVueJestConfig,
    logResultErrors,
    stripInlineSourceMap,
    getCustomTransformer,
    loadSrc
} = require("@vue/vue3-jest/lib/utils");
const generateCode = require("@vue/vue3-jest/lib/generate-code");
const mapLines = require("@vue/vue3-jest/lib/map-lines");
const { vueComponentNamespace } = require("@vue/vue3-jest/lib/constants");

function resolveTransformer(lang = "js", vueJestConfig) {
    const transformer = getCustomTransformer(vueJestConfig.transform, lang);
    if (/^typescript$|tsx?$/.test(lang)) {
        return transformer || typescriptTransformer(lang);
    } else if (/^coffee$|coffeescript$/.test(lang)) {
        return transformer || coffeescriptTransformer;
    }

    return transformer || babelJest.createTransformer();
}

function processScript(scriptPart, filePath, config) {
    if (!scriptPart) {
        return null;
    }

    let content = scriptPart.content;
    let filename = filePath;
    if (scriptPart.src) {
        content = loadSrc(scriptPart.src, filePath);
        filename = scriptPart.src;
    }

    const vueJestConfig = getVueJestConfig(config);
    const transformer = resolveTransformer(scriptPart.lang, vueJestConfig);

    const result = transformer.process(content, filename, config);
    result.code = stripInlineSourceMap(result.code);
    result.map = mapLines(scriptPart.map, result.map);
    return result;
}

function processScriptSetup(descriptor, filePath, config) {
    if (!descriptor.scriptSetup) {
        return null;
    }
    const vueJestConfig = getVueJestConfig(config);
    const content = compileScript(descriptor, {
        id: filePath,
        refTransform: true,
        ...vueJestConfig.compilerOptions
    });
    const contentMap = mapLines(descriptor.scriptSetup.map, content.map);

    const transformer = resolveTransformer(
        descriptor.scriptSetup.lang,
        vueJestConfig
    );

    const result = transformer.process(content.content, filePath, config);
    result.map = mapLines(contentMap, result.map);

    return result;
}

function processTemplate(descriptor, filename, config) {
    const { template, scriptSetup } = descriptor;

    if (!template) {
        return null;
    }

    const vueJestConfig = getVueJestConfig(config);
    if (template.src) {
        template.content = loadSrc(template.src, filename);
    }

    let bindings;
    if (scriptSetup) {
        const scriptSetupResult = compileScript(descriptor, {
            id: filename,
            refTransform: true,
            ...vueJestConfig.compilerOptions
        });
        bindings = scriptSetupResult.bindings;
    }

    const lang =
        (descriptor.scriptSetup && descriptor.scriptSetup.lang) ||
        (descriptor.script && descriptor.script.lang);
    const isTS = /^typescript$|tsx?$/.test(lang);

    const result = compileTemplate({
        id: filename,
        source: template.content,
        filename,
        preprocessLang: template.lang,
        preprocessOptions: vueJestConfig[template.lang],
        compilerOptions: {
            bindingMetadata: bindings,
            mode: "module",
            isTS,
            ...vueJestConfig.compilerOptions
        }
    });

    logResultErrors(result);

    if (isTS) {
        const tsconfig = getTypeScriptConfig(vueJestConfig.tsConfig);
        if (tsconfig) {
            // eslint-disable-next-line global-require
            const { transpileModule } = require("typescript");
            const { outputText } = transpileModule(result.code, { tsconfig });
            return { code: outputText };
        }
    }

    const babelified = transformSync(result.code, {
        filename: "file.js",
        presets: ["@babel/preset-env"]
    });

    return { code: babelified.code };
}

function process(src, filename, config) {
    const { descriptor } = parse(src, { filename });
    const componentNamespace =
        getVueJestConfig(config).componentNamespace || vueComponentNamespace;

    const templateResult = processTemplate(descriptor, filename, config);
    const stylesResult = descriptor.styles
        ? descriptor.styles
              .filter((style) => style.module)
              .map((style) => ({
                  code: processStyle(style, filename, config),
                  moduleName: style.module === true ? "$style" : style.module
              }))
        : null;
    const customBlocksResult = processCustomBlocks(
        descriptor.customBlocks,
        filename,
        componentNamespace,
        config
    );

    let scriptResult;
    const scriptSetupResult = processScriptSetup(descriptor, filename, config);

    if (!scriptSetupResult) {
        scriptResult = processScript(descriptor.script, filename, config);
    }

    const output = generateCode({
        scriptResult,
        scriptSetupResult,
        templateResult,
        customBlocksResult,
        componentNamespace,
        filename,
        stylesResult: stylesResult && stylesResult.length ? stylesResult : null
    });

    return {
        code: output.code,
        map: output.map.toString()
    };
}

module.exports = {
    process,
    getCacheKey(
        fileData,
        filename,
        { config, configString, instrument, rootDir }
    ) {
        return crypto
            .createHash("md5")
            .update(
                babelJest.createTransformer().getCacheKey(fileData, filename, {
                    config,
                    configString,
                    instrument,
                    rootDir
                }),
                "hex"
            )
            .digest("hex");
    }
};
