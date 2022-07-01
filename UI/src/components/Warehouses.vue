<script setup>

import { useWarehousesStore } from "@/store/warehouses";
import ConfigTable from "./ConfigTable.vue";

const COLUMNS = [
    { key: "description", type: "text",     head: "Description" },
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

