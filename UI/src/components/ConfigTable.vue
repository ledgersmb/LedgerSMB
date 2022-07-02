<script setup>

import { storeToRefs } from "pinia";
import { contextRef } from "@/robot-vue";

import { createTableMachine } from "./ConfigTable.machines.js";
import ConfigTableRow from "./ConfigTableRow.vue";

const props = defineProps(["columns", "store"]);
const { items } = storeToRefs(props.store);

const { service, send, state } = createTableMachine(props.store);
const editingId = contextRef(service, "editingId");

</script>

<template>
    <div>
        <table class="dynatable">
            <thead>
                <tr>
                    <th v-for="column in props.columns"
                        :key="column.key">{{ column.head }}</th>
                    <th></th>
                </tr>
            </thead>
            <template v-if="state !== 'loading'">
                <tbody>
                    <ConfigTableRow
                        v-for="item in items"
                        :key="item.id"
                        :columns="props.columns"
                        :deletable="false"
                        :editingId="editingId"
                        :id="item.id"
                        :store="props.store"
                        type="existing"
                        @modifying="send({ type: 'modify', rowId: item.id })"
                        @idle="send('complete')"
                    />
                </tbody>
                <tfoot>
                    <ConfigTableRow
                        :columns="props.columns"
                        :editingId="editingId"
                        id=""
                        :store="props.store"
                        type="new"
                        @modifying="send({ type: 'modify', rowId: -1 })"
                        @idle="send('complete')"
                    />
                </tfoot>
            </template>
            <tbody v-else>
                <tr>
                    <th :colspan="props.columns.length + 1">
                        {{ $t(`Loading...`)}}
                    </th>
                </tr>
            </tbody>
        </table>
    </div>
</template>

