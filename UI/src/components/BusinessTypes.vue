<script setup>

import { useBusinessTypesStore } from "@/store/business-types";
import { useI18n } from "vue-i18n";
import ConfigTable from "./ConfigTable.vue";

const { t } = useI18n();
const COLUMNS = [
    { key: "description", type: "text",     head: t("Description") },
    { key: "discount",    type: "text",     head: t("Discount (%)") }
];

const store = useBusinessTypesStore();

</script>

<template>
    <ConfigTable
        :columns="COLUMNS"
        :store="store"
        storeId="id"
        editRole="business_type_edit"
        createRole="business_type_create" />
</template>
