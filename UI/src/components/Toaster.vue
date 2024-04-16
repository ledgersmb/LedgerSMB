<!-- @format -->

<script setup>
import { computed, inject } from "vue";
import { contextRef } from "@/robot-vue";
import { useSessionUserStore } from "@/store/sessionUser";

import { createToasterMachine } from "@/components/Toaster.machines";
import Toast from "@/components/Toast.vue";

const user = useSessionUserStore();
const wantToaster = computed(() => !user.preferences.__disableToaster);

const { service, send, state } =
    inject("toaster-machine") ||
    createToasterMachine(
        {
            items: []
        },
        {}
    );
const items = contextRef(service, "items");
</script>

<template>
    <div
        v-if="wantToaster"
        class="toaster"
        :class="{ hidden: state !== 'showing' }"
    >
        <Toast
            v-for="item in items"
            :key="item.id"
            :data="item"
            :type="item.type"
            @remove="send({ type: 'remove', item })"
        />
    </div>
</template>
