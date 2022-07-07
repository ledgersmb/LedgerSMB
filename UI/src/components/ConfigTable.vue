<script setup>

import { computed } from "vue";
import { storeToRefs } from "pinia";
import { contextRef } from "@/robot-vue";
import { useSessionUserStore } from "@/store/sessionUser";

import { createTableMachine } from "./ConfigTable.machines.js";
import ConfigTableRow from "./ConfigTableRow.vue";

const props = defineProps([
    "columns",
    "store",
    "createRole",
    "editRole",
    "deletable",
    "storeId"
]);
const user = useSessionUserStore();
const hasRole = user.hasRole; // import the function from the store's getter

const { items } = storeToRefs(props.store);

const { service, send, state } = createTableMachine(props.store);
const editingId = contextRef(service, "editingId");
const hasEdit = computed(() => hasRole(props.editRole));
const hasCreate = computed(() => hasRole(props.createRole));

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
                        :key="item[props.storeId]"
                        :columns="props.columns"
                        :deletable="props.deletable"
                        :editingId="editingId"
                        :id="item[props.storeId]"
                        :store="props.store"
                        :type="hasEdit ? 'existing' : 'uneditable'"
                        @modifying="send({ type: 'modify', rowId: item[props.storeId] })"
                        @idle="send('complete')"
                    />
                </tbody>
                <tfoot v-if="hasCreate">
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

