/** @format */

import {
    action,
    createMachine,
    immediate,
    interpret,
    invoke,
    guard,
    reduce,
    state,
    transition
} from "@/robot-vue";

const registry = require("dijit/registry");
const parser = require("dojo/parser");

function armWidgets(ctx) {
    let maindiv = document.getElementById("maindiv");
    registry.findWidgets(maindiv).forEach((child) => {
        ctx.view.recursivelyResize(child);
    });
    maindiv
        .querySelectorAll("a")
        .forEach((node) => ctx.view._interceptClick(node));
    ctx.view._setFormFocus();
}

function disarmWidgets(ctx) {
    ctx.view._cleanWidgets();
}

function dismissNotify(ctx) {
    if (ctx.dismiss) {
        ctx.dismiss();
        delete ctx.dismiss;
    }
}

function domAcceptable(ctx, { data }) {
    let response = data.response;
    let rv = !(
        response.headers.get("X-LedgerSMB-App-Content") !== "yes" ||
        (response.headers.get("Content-Disposition") || "").startsWith(
            "attachment"
        )
    );
    return rv;
}

async function requestContent(ctx) {
    let headers = new Headers(ctx.options.headers);
    headers.set("X-Requested-With", "XMLHttpRequest");

    document.getElementById("maindiv").removeAttribute("data-lsmb-done");
    // chop off the leading '/' to use relative paths
    let base = window.location.pathname.replace(/[^/]*$/, "");
    let tgt = ctx.tgt;
    let relTgt = tgt.substring(0, 1) === "/" ? tgt.substring(1) : tgt;
    return {
        response: await fetch(base + relTgt, {
            method: ctx.options.method,
            body: ctx.options.data,
            headers: headers
            // additional parameters to consider:
            // mode(cors?), credentials, referrerPolicy?
        })
    };
}

async function retrieveContent(ctx) {
    return await ctx.response.text();
}

async function updateContent(ctx) {
    ctx.view.content = ctx.content;
    let p = new Promise((resolve) => {
        ctx.view.$nextTick(() => {
            resolve();
        });
    });
    await p;
}

async function parseContent(ctx) {
    let maindiv = document.getElementById("maindiv");
    let p = new Promise((resolve) => {
        parser.parse(maindiv).then(() => {
            resolve();
        });
    });
    await p;
    ctx.view.notify({
        title: ctx.options.done || ctx.view.$t("Loaded")
    });
}

function reportError(ctx) {
    ctx.view.reportError(ctx.error);
}

function setContentSrc(ctx, { value }) {
    let dismiss;
    let dismissed = false;
    ctx.notify({
        title: value.options.doing || ctx.view.$t("Loading..."),
        type: "info",
        dismissReceiver: (cb) => {
            if (dismissed) {
                // receiving the callback *after* someone tried to dismiss...
                // do it right now.
                cb();
            } else {
                dismiss = cb;
            }
        }
    });
    return {
        ...ctx,
        tgt: value.tgt,
        options: value.options,
        // 'dismiss' is received delayed; pass a forwarder
        dismiss: () => {
            dismissed = true;
            if (dismiss) {
                dismiss();
            }
        }
    };
}

function setContent(ctx, { data }) {
    return { ...ctx, content: data };
}

function setError(ctx, { data }) {
    return { ...ctx, error: data };
}

function setErrorResponse(ctx, { data }) {
    return { ...ctx, error: data.response };
}

function setResponse(ctx, { data }) {
    return { ...ctx, response: data.response };
}

const machine = createMachine(
    {
        idle: state(
            transition("loadContent", "requesting", reduce(setContentSrc)),
            transition("unloadContent", "unloaded", action(disarmWidgets))
        ),
        requesting: invoke(
            requestContent,
            transition(
                "loadContent",
                "requesting",
                action(dismissNotify),
                reduce(setContentSrc)
            ),
            transition(
                "unloadContent",
                "unloaded",
                action(dismissNotify),
                action(disarmWidgets)
            ),
            transition(
                "done",
                "retrieving",
                guard(domAcceptable),
                reduce(setResponse)
            ),
            transition("done", "error", reduce(setErrorResponse)),
            transition("error", "error", reduce(setError))
        ),
        retrieving: invoke(
            retrieveContent,
            transition(
                "loadContent",
                "requesting",
                action(dismissNotify),
                reduce(setContentSrc)
            ),
            transition(
                "unloadContent",
                "unloaded",
                action(dismissNotify),
                action(disarmWidgets)
            ),
            transition("done", "disarming", reduce(setContent)),
            transition("error", "error", reduce(setError))
        ),
        disarming: state(immediate("updating", action(disarmWidgets))),
        updating: invoke(
            updateContent,
            transition("done", "parsing"),
            transition("error", "error", reduce(setError))
        ),
        parsing: invoke(
            parseContent,
            transition("done", "arming"),
            transition("error", "error", reduce(setError))
        ),
        arming: state(
            immediate("idle", action(armWidgets), action(dismissNotify))
        ),
        error: invoke(
            reportError,
            transition("done", "idle", action(dismissNotify))
        ),
        unloaded: state()
    },
    (ctx) => ({ ...ctx })
);

function createServerUIMachine(initialContext, callback) {
    return interpret(machine, callback, initialContext);
}

export { createServerUIMachine };
