<script setup>

import { storeToRefs } from "pinia";
import { computed } from "vue";
import { contextRef } from "@/robot-vue";

import { warehousesMachine } from "./Warehouses.machines.js";
import { useWarehousesStore } from "@/store/warehouses";
import WarehouseRow from "./WarehouseRow.vue";

const COLUMNS = [
    { key: "description", type: "text",     head: "Description" },
];

const warehousesStore = useWarehousesStore();
const { warehouses } = storeToRefs(warehousesStore);

const { service, send, state } = warehousesMachine(warehousesStore);
const editingRow = contextRef(service, "rowId");
const newBuffer = contextRef(service, "newData");
const editBuffer = contextRef(service, "editData");

const updating = computed(
    () => (state.value==="adding"
        || state.value==="saving"
        || state.value==="deleting"));

function rowEditable(id) {
    return (editingRow.value===id || !editingRow.value) && !updating.value;
}

function rowEditing(id) {
    return editingRow.value===id;
}

function rowData(data) {
    return editingRow.value===data.id ? editBuffer.value : data;
}
</script>

<style local>
.neutral {
    border-color: transparent;
}
</style>

<template>
    <div>
        <table class="dynatable report">
            <thead>
                <tr>
                    <th v-for="column in COLUMNS"
                        :key="column.key">{{ column.head }}</th>
                    <th></th>
                </tr>
            </thead>
            <template v-if="state !== 'loading'">
                <tbody>
                    <WarehouseRow
                        v-for="warehouse in warehouses"
                        :columns="COLUMNS"
                        :data="rowData(warehouse)"
                        :editable="rowEditable(warehouse.id)"
                        :editing="rowEditing(warehouse.id)"
                        :key="warehouse.id"
                        type="existing"
                        @edit="send({ type: 'edit', rowId: warehouse.id })"
                        @cancel="send('cancel')"
                        @save="send('save')"
                        @update="(data) => send({ type: 'updateEdit', data })"
                        @delete="send({ type: 'delete', rowId: warehouse.id })"
                    />
                </tbody>
                <tfoot>
                    <WarehouseRow
                        :columns="COLUMNS"
                        :data="newBuffer"
                        :editable="!editingRow && !updating"
                        :editing="true"
                        type="new"
                        @update="(data) => send({ type: 'updateNew', data })"
                        @add="send({ type: 'add' })"
                        />
                </tfoot>
            </template>
            <tbody v-else>
                <tr>
                    <th :colspan="COLUMNS.length + 1">
                        {{ $t(`Loading...`)}}
                    </th>
                </tr>
            </tbody>
        </table>
    </div>
</template>

