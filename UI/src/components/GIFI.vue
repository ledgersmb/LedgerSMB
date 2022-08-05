<script setup>

import { useGIFIsStore } from "@/store/gifis";
import { useI18n } from "vue-i18n";
import ConfigTable from "./ConfigTable.vue";

import ImportCsvGifi from "@/components/ImportCSV-GIFI";

const { t } = useI18n();
const COLUMNS = [
    { key: "accno", type: "text",            head: t("Code") },
    { key: "description", type: "text",      head: t("Description") },
];

const store = useGIFIsStore();

</script>

<style scoped>

.import-section {
    margin-top: 3em;
}

.import-section h2 {
    text-align: left;
}

</style>

<template>
    <h1 class="listtop">{{ t("Configure GIFI codes") }}</h1>
    <ConfigTable
        :columns="COLUMNS"
        :store="store"
        storeId="accno"
        editRole="gifi_edit"
        createRole="gifi_create" />
    <div class="import-section">
        <h2 class="listheading">{{ t("Import") }}</h2>
        <ImportCsvGifi />
    </div>
</template>
