/** @format */

import {
    createMachine,
    immediate,
    interpret,
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
        showing: state(
            transition("dismiss", "removing"),
            transition("dismiss-immediate", "removing"),
            transition("hold", "holding")
        ),
        holding: state(
            transition("dismiss", "holdingDone"),
            transition("dismiss-immediate", "removing"),
            transition("release", "showing")
        ),
        holdingDone: state(
            transition("dismiss-immediate", "removing"),
            transition("release", "removing")
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
