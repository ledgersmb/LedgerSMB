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

function handleError(ctx, error) {
    return { ...ctx, error };
}

function markRowEditing(ctx, { rowId }) {
    return { ...ctx, rowId };
}

function markIdle(ctx) {
    return { ...ctx, rowId: -1 };
}

async function initializeWarehouses(ctx) {
    return ctx.warehousesStore.initialize();
}

function initializeWarehouse(ctx) {
    return { ...ctx, data: ctx.store.getById(ctx.rowId) };
}

function handleInput(ctx, { key, value }) {
    ctx.data[key] = value;
    return ctx;
}

async function addWarehouse(ctx) {
    return ctx.store.add(ctx.data);
}

async function deleteWarehouse(ctx) {
    return ctx.store.del(ctx.rowId);
}

async function acquireWarehouse(ctx) {
    return ctx.store.get(ctx.rowId);
}

async function saveWarehouse(ctx) {
    return ctx.store.save(ctx.rowId, ctx.data);
}

const warehousesMachine = createMachine(
    {
        loading: invoke(
            initializeWarehouses,
            transition("done", "idle"),
            transition("error", "error")
        ),
        idle: state(
            transition("modify", "modifying", reduce(markRowEditing)),
        ),
        modifying: state(
            transition("complete", "idle", reduce(markIdle))
        ),
        error: state()
    },
    (initialContext) => ({ rowId: undefined, ...initialContext })
);


const warehouseMachine = createMachine(
    {
        initializing: state(
            immediate("idle", reduce(initializeWarehouse))
        ),
        idle: state(
            transition("update", "idle",
                       guard((ctx) => ctx.adding),
                       reduce(handleInput)),
            transition("add", "adding", guard((ctx) => ctx.adding)),
            transition("modify", "acquiring"),
            transition("disable", "unmodifiable")
        ),
        acquiring: invoke(
            acquireWarehouse,
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
            saveWarehouse,
            transition("done", "initializing"),
            transition("error", "error", reduce(handleError))
        ),
        deleting: invoke(
            deleteWarehouse,
            transition("done", "deleted"),
            transition("error", "error", reduce(handleError))
        ),
        deleted: state(),
        adding: invoke(
            addWarehouse,
            transition("done", "initializing"),
            transition("error", "error", reduce(handleError))
        ),
        unmodifiable: state(
            transition("enable", "idle")
        ),
        error: state()
    },
    (ctx) => ({ ...ctx })
);


function cbStateEntry(service) {
    let current = service.machine.current;
    let ctx = service.context;

    if (current === "idle") {
        ctx.rowId = "";
    }
}

function createWarehousesMachine(warehousesStore) {
    return interpret(warehousesMachine, cbStateEntry, {
        warehousesStore,
        editingId: -1
    });
}


function createWarehouseMachine(warehousesStore, { ctx, cb }) {
    return interpret(warehouseMachine, cb, {
        store: warehousesStore,
        ...ctx
    });
}


export { createWarehousesMachine, createWarehouseMachine };
