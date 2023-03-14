<script setup>

import { useSICsStore } from "@/store/sics";
import { useI18n } from "vue-i18n";
import ConfigTable from "@/components/ConfigTable.vue";

import ImportCsvSic from "@/views/ImportCSV-SIC";

const { t } = useI18n();
const COLUMNS = [
    { key: "code", type: "text",            head: t("Code") },
    { key: "description", type: "text",     head: t("Description") },
];

const store = useSICsStore();

</script>

<template>
    <h1 class="listtop">{{ t("Configure Standard Industry Codes (SIC)") }}</h1>
    <ConfigTable
        :columns="COLUMNS"
        :store="store"
        storeId="code"
        editRole="sic_edit"
        createRole="sic_create" />
    <div class="import-section">
        <h2 class="listheading">{{ t("Import") }}</h2>
        <ImportCsvSic />
    </div>
</template>

<style scoped>

.import-section {
    margin-top: 3em;
}

.import-section h2 {
    text-align: left;
}

</style>
