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

function progressNotify(fn, progress) {
    return async (ctx) => {
        let dismiss;

        if (progress) {
            let cbp = ctx.notifications[progress];
            if (cbp) {
                cbp(ctx, (d) => {
                    dismiss = d;
                });
            }
        }
        return fn(ctx).finally((value) => {
            if (dismiss) {
                dismiss();
            }
            return value;
        });
    };
}

function notify(notification) {
    return (ctx) => {
        let cb = ctx.notifications[notification];
        if (cb) {
            cb(ctx);
        }
    };
}

function handleError(ctx, error) {
    return { ...ctx, error };
}

function markRowEditing(ctx, { rowId }) {
    return { ...ctx, editingId: rowId };
}

function markIdle(ctx) {
    return { ...ctx, editingId: "" };
}

async function initializeTable(ctx) {
    return ctx.store.initialize();
}

function initializeRow(ctx) {
    return { ...ctx, data: ctx.store.getById(ctx.rowId) };
}

function handleInput(ctx, { key, value }) {
    ctx.data[key] = value;
    return ctx;
}

async function addItem(ctx) {
    return ctx.store.add(ctx.data);
}

async function deleteItem(ctx) {
    return ctx.store.del(ctx.rowId);
}

async function acquireItem(ctx) {
    return ctx.store.get(ctx.rowId);
}

async function saveItem(ctx) {
    return ctx.store.save(ctx.rowId, ctx.data);
}

const warehousesMachine = createMachine(
    {
        loading: invoke(
            initializeTable,
            transition("done", "idle"),
            transition("error", "error")
        ),
        idle: state(transition("modify", "modifying", reduce(markRowEditing))),
        modifying: state(transition("complete", "idle", reduce(markIdle))),
        error: state()
    },
    (initialContext) => ({ rowId: undefined, ...initialContext })
);

const warehouseMachine = createMachine(
    {
        initializing: state(immediate("idle", reduce(initializeRow))),
        idle: state(
            transition(
                "update",
                "idle",
                guard((ctx) => ctx.adding),
                reduce(handleInput)
            ),
            transition(
                "add",
                "adding",
                guard((ctx) => ctx.adding)
            ),
            transition("modify", "acquiring"),
            transition("disable", "unmodifiable")
        ),
        acquiring: invoke(
            progressNotify(acquireItem, "acquiring"),
            transition("done", "modifying"),
            transition("error", "error", reduce(handleError))
        ),
        modifying: state(
            transition("update", "modifying", reduce(handleInput)),
            transition("save", "saving"),
            transition("delete", "deleting"),
            transition("cancel", "initializing")
        ),
        saving: invoke(
            progressNotify(saveItem, "saving"),
            transition("done", "initializing", action(notify("saved"))),
            transition("error", "error", reduce(handleError))
        ),
        deleting: invoke(
            progressNotify(deleteItem, "deleting"),
            transition("done", "deleted", action(notify("deleted"))),
            transition("error", "error", reduce(handleError))
        ),
        deleted: state(),
        adding: invoke(
            progressNotify(addItem, "adding"),
            transition("done", "initializing", action(notify("added"))),
            transition("error", "error", reduce(handleError))
        ),
        unmodifiable: state(transition("enable", "idle")),
        error: state(transition("restart", "initializing"))
    },
    (ctx) => ({ ...ctx })
);

function createTableMachine(store, { cb = {} }) {
    return interpret(warehousesMachine, cb, {
        store,
        editingId: ""
    });
}

function createRowMachine(store, { ctx, cb }) {
    return interpret(warehouseMachine, cb, {
        store,
        ...ctx
    });
}

export { createTableMachine, createRowMachine };
