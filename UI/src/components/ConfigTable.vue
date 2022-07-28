<script setup>

import { computed, inject } from "vue";
import { useI18n } from "vue-i18n";
import { storeToRefs } from "pinia";
import { contextRef } from "@/robot-vue";
import { useSessionUserStore } from "@/store/sessionUser";

import { createTableMachine } from "./ConfigTable.machines.js";
import ConfigTableRow from "./ConfigTableRow.vue";

const { t } = useI18n();

const props = defineProps([
    "columns",
    "store",
    "createRole",
    "editRole",
    "deletable",
    "storeId"
]);
const notify = inject("notify");

const user = useSessionUserStore();
const hasRole = user.hasRole; // import the function from the store's getter

const { items } = storeToRefs(props.store);

const { service, send, state } = createTableMachine(props.store, {
    cb: {
        error: () => {
            notify({ title: t("Failed"), type: "error" });
        }
    }
});
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
            <tbody v-if="state == 'loading'">
                <tr>
                    <th :colspan="props.columns.length + 1">
                        {{ $t("Loading...")}}
                    </th>
                </tr>
            </tbody>
            <tbody v-else-if="state == 'error'">
                <tr>
                    <th :colspan="props.columns.length + 1">
                        {{ $t("Error loading data...")}}
                    </th>
                </tr>
            </tbody>
            <template v-else>
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
        </table>
    </div>
</template>

