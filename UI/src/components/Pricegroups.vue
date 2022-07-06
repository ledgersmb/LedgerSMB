<script setup>

import { usePricegroupsStore } from "@/store/pricegroups";
import { useI18n } from "vue-i18n";
import ConfigTable from "./ConfigTable.vue";

const { t } = useI18n();
const COLUMNS = [
    { key: "description", type: "text",     head: t("Description") },
];

const pricegroupsStore = usePricegroupsStore();

</script>

<template>
    <ConfigTable
        :columns="COLUMNS"
        :store="pricegroupsStore"
        editRole="pricegroup_edit"
        createRole="pricegroup_create" />
</template>

