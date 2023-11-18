<script setup>

import { useLanguagesStore } from "@/store/languages";
import { useI18n } from "vue-i18n";
import ConfigTable from "@/components/ConfigTable.vue";

const { t } = useI18n();
const COLUMNS = [
    { key: "code",        type: "text",     head: t("Code") },
    { key: "description", type: "text",     head: t("Description") },
];

const store = useLanguagesStore();

</script>

<template>
    <h1 class="listtop">{{ t("Configure languages") }}</h1>
    <ConfigTable
        :columns="COLUMNS"
        :store="store"
        storeId="code"
        defaultSelectable="true"
        editRole="language_edit"
        createRole="language_create" />
</template>
