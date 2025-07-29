/** @format */

const MarkdownInclude = require("markdown-include");
const browserslist = require("browserslist");
const lite = require("caniuse-lite");
const packageJson = require("../package.json");

function _isNextVersion(v1, v2) {
    let p1 = v1.match(/(\d+)(\.(\d+))?/);
    let p2 = v2.match(/(\d+)(\.(\d+))?/);
    return (
        v2 &&
        ((+p1[1] === +p2[1] + 1 && !p1[3] && !p2[3]) ||
            (+p1[1] === +p2[1] && +p1[3] === +p2[3] + 1))
    );
}

MarkdownInclude.registerPlugin({
    pattern: /^<<browsers_list>>$/gm,
    replace: function () {
        var earliest = {};

        // Find earliests browsers
        browserslist()
            .sort()
            .forEach(function (b) {
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
        /* eslint guard-for-in:0 */
        for (const c of ["Desktop", "Mobile"]) {
            markdown += "\n### " + c + "\n\n";
            markdown += "| " + "Browser Name".padEnd(20, " ");
            markdown += "| " + "Earliest".padEnd(9, " ");
            markdown += "| " + "Versions".padEnd(44, " ") + "|\n";
            markdown += "| " + "---".padEnd(19, "-");
            markdown += "| " + "---".padEnd(8, "-");
            markdown += "| " + "---".padEnd(43, "-") + "|\n";

            for (var browser in earliest[c]) {
                var entry = earliest[c][browser];
                let versions = [];
                let v1 = "";
                let v2 = "";
                // Pack versions
                let vs = entry.versions.sort((a, b) =>
                    a.localeCompare(b, undefined, { numeric: true })
                );

                var v;
                /* eslint no-cond-assign:0 */
                while ((v = vs.shift()) || v1) {
                    if (v && v.includes("-")) {
                        let [v01, v02] = v.split("-");
                        if (_isNextVersion(v01, v2)) {
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
                            _isNextVersion(v, v2) ||
                            (!v2 && _isNextVersion(v, v1))
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
                var l = "";
                var line =
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
});

MarkdownInclude.registerPlugin({
    pattern: /<<LSMB_VERSION>>/gm,
    replace: function () {
        return packageJson.version;
    }
});

// do something with compiled files
var tmp = require("tmp");
var fs = require("fs");

tmp.file(
    {
        prefix: "markdown-",
        postfix: ".json",
        keep: false
    },
    function (err, path) {
        if (err) {
            throw err;
        }
        fs.writeFileSync(
            path,
            `{
                "build" : "../README.md",
                "files" : ["../doc/sources/_README.md"]
            }`
        );
        MarkdownInclude.compileFiles(path);
    }
);
