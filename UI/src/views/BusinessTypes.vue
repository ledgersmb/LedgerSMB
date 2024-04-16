<!-- @format -->
<!-- eslint-disable prettier/prettier -->

<script setup>
import { useBusinessTypesStore } from "@/store/business-types";
import { useI18n } from "vue-i18n";
import ConfigTable from "@/components/ConfigTable.vue";

const { t } = useI18n();
const COLUMNS = [
    { key: "description", type: "text", head: t("Description") },
    { key: "discount",    type: "text", head: t("Discount (%)") }
];

const store = useBusinessTypesStore();

</script>

<template>
    <h1 class="listtop">{{ $t("Configure Type of Businesses") }}</h1>
    <ConfigTable
        :columns="COLUMNS"
        :store="store"
        storeId="id"
        editRole="business_type_edit"
        createRole="business_type_create"
    />
</template>
