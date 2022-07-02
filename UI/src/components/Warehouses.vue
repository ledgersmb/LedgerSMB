<script setup>

import { useWarehousesStore } from "@/store/warehouses";
import { useI18n } from "vue-i18n";
import ConfigTable from "./ConfigTable.vue";

const { t } = useI18n();
const COLUMNS = [
    { key: "description", type: "text",     head: t("Description") },
];

const warehousesStore = useWarehousesStore();

</script>

<style local>
.neutral {
    border-color: transparent;
}
</style>

<template>
    <ConfigTable
        :columns="COLUMNS"
        :store="warehousesStore" />
</template>

