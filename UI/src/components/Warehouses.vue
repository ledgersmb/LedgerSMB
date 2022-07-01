<script setup>

import { storeToRefs } from "pinia";
import { computed, provide } from "vue";
import { contextRef } from "@/robot-vue";

import { createWarehousesMachine } from "./Warehouses.machines.js";
import { useWarehousesStore } from "@/store/warehouses";
import WarehouseRow from "./WarehouseRow.vue";

const COLUMNS = [
    { key: "description", type: "text",     head: "Description" },
];

const warehousesStore = useWarehousesStore();
const { warehouses } = storeToRefs(warehousesStore);

const { service, send, state } = createWarehousesMachine(warehousesStore);
const editingId = contextRef(service, "editingId");

provide("configStore", warehousesStore);

</script>

<style local>
.neutral {
    border-color: transparent;
}
</style>

<template>
    <div>
        <table class="dynatable">
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
                        :key="warehouse.id"
                        :id="warehouse.id"
                        :editingId="editingId"
                        :deletable="false"
                        type="existing"
                        @modifying="send({ type: 'modify', rowId: warehouse.id })"
                        @idle="send('complete')"
                    />
                </tbody>
                <tfoot>
                    <WarehouseRow
                        :columns="COLUMNS"
                        id=""
                        :editingId="editingId"
                        type="new"
                        @modifying="send({ type: 'modify', rowId: -1 })"
                        @idle="send('complete')"
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

