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
    <h1 class="listtop">{{ t("Configure pricegroups") }}</h1>
    <ConfigTable
        :columns="COLUMNS"
        :store="pricegroupsStore"
        storeId="id"
        editRole="pricegroup_edit"
        createRole="pricegroup_create" />
</template>

