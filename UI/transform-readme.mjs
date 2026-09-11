#!/usr/bin/env node
/** @format */

import MarkdownInclude from "markdown-include";
import browserslist from "browserslist";
import lite from "caniuse-lite";
import { readFileSync, writeFileSync } from "fs";
import { fileSync } from "tmp";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load package.json dynamically
const packageJsonPath = join(__dirname, "./package.json");
const packageJson = JSON.parse(readFileSync(packageJsonPath, "utf-8"));

function isNextVersion(v1, v2) {
    let p1 = v1.match(/(\d+)(\.(\d+))?/);
    let p2 = v2.match(/(\d+)(\.(\d+))?/);
    return (
        v2 &&
        ((+p1[1] === +p2[1] + 1 && !p1[3] && !p2[3]) ||
            (+p1[1] === +p2[1] && +p1[3] === +p2[3] + 1))
    );
}

function generateBrowsersList() {
    const earliest = {};

    browserslist()
        .sort()
        .forEach((b) => {
            let [browser, version] = b.split(/\s+/);
            let category = browser.match(
                /^(\w+_\w+|android|baidu|bb|kaios|samsung)$/
            )
                ? "Mobile"
                : "Desktop";

            if (!lite.agents[browser]) {
                return;
            }
            if (earliest[category] === undefined) {
                earliest[category] = {};
            }
            if (earliest[category][browser] === undefined) {
                earliest[category][browser] = { time: null };
                earliest[category][browser].name =
                    lite.agents[browser].browser;
                earliest[category][browser].versions = [];
            }
            let time = lite.agents[browser].release_date[version];

            if (time !== null) {
                // Unreleased versions have time === null; exclude them
                if (
                    earliest[category][browser].time === null ||
                    earliest[category][browser].time > time
                ) {
                    earliest[category][browser].version = version;

                    if (time) {
                        let ts = new Date(time * 1000);
                        let month = "00" + (ts.getMonth() + 1);
                        let year =
                            1900 +
                            ts.getYear() +
                            "-" +
                            month.substr(month.length - 2);
                        earliest[category][browser].year = year;
                        earliest[category][browser].time = time;
                    } else {
                        earliest[category][browser].year = "<missing>";
                    }
                }
                earliest[category][browser].versions.push(version);
            }
        });

    let markdown = "";
    for (const c of ["Desktop", "Mobile"]) {
        markdown += "\n### " + c + "\n\n";
        markdown += "| " + "Browser Name".padEnd(20, " ");
        markdown += "| " + "Earliest".padEnd(9, " ");
        markdown += "| " + "Versions".padEnd(44, " ") + "|\n";
        markdown += "| " + "---".padEnd(19, "-");
        markdown += "| " + "---".padEnd(8, "-");
        markdown += "| " + "---".padEnd(43, "-") + "|\n";

        for (const browser in earliest[c]) {
            const entry = earliest[c][browser];
            let versions = [];
            let v1 = "";
            let v2 = "";
            // Pack versions
            let vs = entry.versions.sort((a, b) =>
                a.localeCompare(b, undefined, { numeric: true })
            );

            let v;
            while ((v = vs.shift()) || v1) {
                if (v && v.includes("-")) {
                    let [v01, v02] = v.split("-");
                    if (isNextVersion(v01, v2)) {
                        v2 = v02;
                        continue;
                    } else if (v1 === "") {
                        v1 = v01;
                        v2 = v02;
                        continue;
                    }
                    vs.unshift(v);
                } else if (v && +v) {
                    if (
                        isNextVersion(v, v2) ||
                        (!v2 && isNextVersion(v, v1))
                    ) {
                        v2 = v;
                        continue;
                    } else if (v1 === "") {
                        v1 = v;
                        continue;
                    }
                    vs.unshift(v);
                } else if (v && v1) {
                    vs.unshift(v);
                } else if (v) {
                    v1 = v;
                }
                versions.push(v1 !== v2 && v2 !== "" ? v1 + "-" + v2 : v1);
                v1 = "";
                v2 = "";
            }
            let l = "";
            let line =
                "| " +
                entry.name.padEnd(19, " ") +
                " | " +
                entry.year.padEnd(8, " ") +
                " | ";
            while (versions.length) {
                while (
                    versions.length &&
                    l.length + versions[0].length < 42
                ) {
                    l += versions.shift();
                    if (versions.length) {
                        l += ", ";
                    }
                }
                markdown += line + l.padEnd(43, " ") + " |\n";
                line = "| " + "".padEnd(20, " ");
                line += "| " + "".padEnd(9, " ") + "| ";
                l = "";
            }
        }
    }
    return markdown;
}

// Register plugins
MarkdownInclude.registerPlugin({
    pattern: /^<<browsers_list>>$/gm,
    replace: generateBrowsersList
});

MarkdownInclude.registerPlugin({
    pattern: /<<LSMB_VERSION>>/gm,
    replace: () => packageJson.version
});

// Compile markdown files
try {
    const tmpFile = fileSync({
        prefix: "markdown-",
        postfix: ".json",
        keep: false
    });

    const configJson = {
        build: "../README.md",
        files: ["../doc/sources/_README.md"]
    };

    writeFileSync(tmpFile.name, JSON.stringify(configJson, null, 2));
    MarkdownInclude.compileFiles(tmpFile.name);
    console.log("✓ Markdown compilation complete");
} catch (err) {
    console.error("✗ Error during markdown compilation:", err.message);
    process.exit(1);
}
