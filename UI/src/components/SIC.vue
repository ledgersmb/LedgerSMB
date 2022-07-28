<script setup>

import { useSICsStore } from "@/store/sics";
import { useI18n } from "vue-i18n";
import ConfigTable from "./ConfigTable.vue";

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
    <lsmb-button disabled="disabled">{{ t("Import") }}</lsmb-button>
</template>
