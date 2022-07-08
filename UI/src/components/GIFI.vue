<script setup>

import { useGIFIsStore } from "@/store/gifis";
import { useI18n } from "vue-i18n";
import ConfigTable from "./ConfigTable.vue";

const { t } = useI18n();
const COLUMNS = [
    { key: "accno", type: "text",            head: t("Code") },
    { key: "description", type: "text",      head: t("Description") },
];

const store = useGIFIsStore();

</script>

<template>
    <ConfigTable
        :columns="COLUMNS"
        :store="store"
        storeId="accno"
        editRole="gifi_edit"
        createRole="gifi_create" />
    <lsmb-button disabled="disabled">Import</lsmb-button>
</template>
