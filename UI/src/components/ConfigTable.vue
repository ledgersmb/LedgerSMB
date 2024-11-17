<!-- @format -->

<script setup>
import { computed, inject } from "vue";
import { useI18n } from "vue-i18n";
import { storeToRefs } from "pinia";
import { contextRef } from "@/robot-vue";
import { useSessionUserStore } from "@/store/sessionUser";

import { createTableMachine } from "@/components/ConfigTable.machines.js";
import ConfigTableRow from "@/components/ConfigTableRow.vue";

const props = defineProps([
    "columns",
    "defaultSelectable",
    "store",
    "createRole",
    "editRole",
    "deletable",
    "storeId"
]);
const notify = inject("notify");

const { t } = useI18n();
const user = useSessionUserStore();
const hasRole = user.hasRole; // import the function from the store's getter

const { items, _links, apiURL } = storeToRefs(props.store);

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

const absURL = new URL(apiURL.value, window.location);
function u(relURL) {
    return new URL(relURL, absURL);
}
</script>

<template>
    <div>
        <table class="dynatable">
            <thead>
                <tr>
                    <th v-if="props.defaultSelectable">
                        {{ $t("Default") }}
                    </th>
                    <th v-for="column in props.columns" :key="column.key">
                        {{ column.head }}
                    </th>
                    <th />
                </tr>
            </thead>
            <tbody v-if="state == 'loading'" class="dynatableLoading">
                <tr>
                    <th :colspan="props.columns.length + 1">
                        {{ $t("Loading...") }}
                    </th>
                </tr>
            </tbody>
            <tbody v-else-if="state == 'error'" class="dynatableError">
                <tr>
                    <th :colspan="props.columns.length + 1">
                        {{ $t("Error loading data...") }}
                    </th>
                </tr>
            </tbody>
            <template v-else>
                <tbody class="dynatableData">
                    <ConfigTableRow
                        v-for="item in items"
                        :id="item[props.storeId]"
                        :key="item[props.storeId]"
                        :defaultSelectable="props.defaultSelectable"
                        :isDefault="item.default"
                        :columns="props.columns"
                        :deletable="props.deletable"
                        :editingId="editingId"
                        :store="props.store"
                        :type="hasEdit ? 'existing' : 'uneditable'"
                        @modifying="
                            send({ type: 'modify', rowId: item[props.storeId] })
                        "
                        @savingAsDefault="send('saveDefault')"
                        @idle="send('complete')"
                    />
                </tbody>
                <tfoot v-if="hasCreate">
                    <ConfigTableRow
                        :defaultSelectable="props.defaultSelectable"
                        :columns="props.columns"
                        :editingId="editingId"
                        :store="props.store"
                        type="new"
                        @modifying="send({ type: 'modify', rowId: -1 })"
                        @idle="send('complete')"
                    />
                </tfoot>
            </template>
        </table>
    </div>
    <div v-if="_links.length > 0">
        <span>{{ $t("Download: ") }}</span>
        <span v-for="link in _links" :key="link.href">
            <a :href="u(link.href)" target="_blank">[ {{ link.title }} ]</a>
        </span>
    </div>
</template>
