/** @format */

import {
    createMachine,
    immediate,
    interpret,
    invoke,
    guard,
    reduce,
    state,
    transition
} from "@/robot-vue";

let seq = 1;

function addItem(ctx, { item }) {
    ctx.items.push({ id: seq++, ...item });
    return ctx;
}

function removeItem(ctx, { item }) {
    const index = ctx.items.findIndex((w) => w.id === item.id);
    ctx.items.splice(index, 1);
    return ctx;
}

function delayRemoval(ctx) {
    const duration = ctx.duration && ctx.duration === "short" ? 2 : 10;
    return Promise.any([
        new Promise((resolve) => {
            ctx.dismiss = resolve;
        }),
        new Promise((resolve) => {
            window.setTimeout(() => {
                resolve(1);
            }, duration * 1000);
        })
    ]);
}

function handleDismiss(ctx) {
    ctx.dismiss(1);
    return ctx;
}

function handleError(ctx, error) {
    return { ...ctx, error: error };
}

const toasterMachine = createMachine(
    {
        idle: state(transition("add", "showing", reduce(addItem))),
        showing: state(
            transition("add", "showing", reduce(addItem)),
            transition("remove", "postRemoval", reduce(removeItem))
        ),
        postRemoval: state(
            immediate(
                "showing",
                guard((ctx) => ctx.items.length > 0)
            ),
            immediate("idle")
        )
    },
    (initialContext) => ({ ...initialContext })
);

const toastMachine = createMachine(
    {
        showing: invoke(
            delayRemoval,
            transition("done", "removing"),
            transition("error", "error", reduce(handleError)),
            transition("dismiss", "removing", reduce(handleDismiss))
        ),
        removing: state(immediate("removed")),
        removed: state(),
        error: state()
    },
    (ctx) => ({ ...ctx })
);

function createToasterMachine(ctx, { cb }) {
    return interpret(toasterMachine, cb, {
        ...ctx
    });
}

function createToastMachine(ctx, { cb }) {
    return interpret(toastMachine, cb, {
        ...ctx
    });
}

export { createToasterMachine, createToastMachine };
