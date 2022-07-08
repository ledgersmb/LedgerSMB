<script setup>

import { useLanguagesStore } from "@/store/languages";
import { useI18n } from "vue-i18n";
import ConfigTable from "./ConfigTable.vue";

const { t } = useI18n();
const COLUMNS = [
    { key: "code", type: "text",            head: t("Code") },
    { key: "description", type: "text",     head: t("Description") },
];

const store = useLanguagesStore();

</script>

<template>
    <ConfigTable
        :columns="COLUMNS"
        :store="store"
        storeId="code"
        editRole="language_edit"
        createRole="language_create" />
</template>
