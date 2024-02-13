<!-- eslint-disable vue/multi-word-component-names -->

<script setup>

import { useCountriesStore } from "@/store/countries";
import { useI18n } from "vue-i18n";
import ConfigTable from "@/components/ConfigTable.vue";

const { t } = useI18n();
const COLUMNS = [
    { key: "code",       type: "text",            head: t("Code") },
    { key: "name",       type: "text",            head: t("Name") },
];

const store = useCountriesStore();

</script>

<template>
    <h1 class="listtop">{{ $t("Configure countries") }}</h1>
    <ConfigTable
        :columns="COLUMNS"
        :store="store"
        storeId="code"
        defaultSelectable="true"
        editRole="country_edit"
        createRole="country_create" />
</template>
