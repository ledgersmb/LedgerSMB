/** @format */

import {
    action,
    createMachine,
    interpret,
    invoke,
    reduce,
    state,
    transition
} from "@/robot-vue";


import { reactive } from "vue";
import { cloneDeep } from "lodash";

function handleError(ctx, error) {
    return { ...ctx, error };
}

function clearEditBuffer(ctx) {
    return { ...ctx, "editData": {} };
}

function updateEditBuffer(ctx, { data }) {
    ctx.editData[data.key] = data.value;
    return ctx;
}

function clearNewBuffer(ctx) {
    return { ...ctx, "newData": {} };
}

function updateNewBuffer(ctx, { data }) {
    ctx.newData[data.key] = data.value;
    return ctx;
}

function markRowEditing(ctx, { rowId }) {
    Object.assign(ctx.editData, ctx.warehousesStore.getById(rowId));
    return { ...ctx, rowId };
}

async function initializeWarehouses(ctx) {
    return ctx.warehousesStore.initialize();
};

async function addWarehouse(ctx) {
    return ctx.warehousesStore.add(ctx.newData);
};

async function deleteWarehouse(ctx, { rowId }) {
    return ctx.warehousesStore.del(rowId);
}

async function saveWarehouse(ctx) {
    return ctx.warehousesStore.save(ctx.rowId, ctx.editData);
};

const machine = createMachine({
    loading: invoke(
        initializeWarehouses,
        transition("done", "idle"),
        transition("error", "error")
    ),
    idle: state(
        transition("edit", "editing", reduce(markRowEditing)),
        transition("delete", "deleting"),
        transition("add", "adding"),
        transition("updateNew", "idle", reduce(updateNewBuffer))
    ),
    editing: state(
        transition("cancel", "idle"),
        transition("save", "saving"),
        transition("updateEdit", "editing", reduce(updateEditBuffer))
    ),
    saving: invoke(
        // the event which triggered the 'saving' state
        // is passed as the event to the 'saveWarehouse' function
        saveWarehouse,
        transition("error", "error", reduce(handleError)),
        transition("done", "idle", reduce(clearEditBuffer))
    ),
    deleting: invoke(
        // the event which triggered the 'deleting' state
        // is passed as the event to the 'deleteWarehouse' function
        deleteWarehouse,
        transition("error", "error", reduce(handleError)),
        transition("done", "idle")
    ),
    adding: invoke(
        // the event which triggered the 'adding' state
        // is passed as the event to the 'addWarehouse' function
        addWarehouse,
        transition("error", "error", reduce(handleError)),
        transition("done", "idle", reduce(clearNewBuffer))
    ),
    error: state()
}, (initialContext) => ({ rowId: "", ...initialContext }));

function cbStateEntry(service) {
    let current = service.machine.current;
    let ctx = service.context;

    if (current === "idle") {
        ctx.rowId = "";
    }
}

function warehousesMachine(warehousesStore) {
    return interpret(
        machine,
        cbStateEntry,
        { warehousesStore, editData: {}, newData: {} });
}

export {
    warehousesMachine
};
