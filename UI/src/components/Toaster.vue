<script setup>

import { inject } from "vue";
import { contextRef } from "@/robot-vue";

import { createToasterMachine } from "./Toaster.machines";
import Toast from "./Toast.vue";


const { service, send, state } = (inject("toaster-machine") || createToasterMachine({
    items: []
}, {}));
const items = contextRef(service, "items");


</script>

<style local>
.toaster {
    position: absolute;
    right: 5%;
    top: 20px;
    z-index: 2;
    width: 50em;
    max-width: 60%;
    box-sizing: border-box;
}

.toaster.hidden {
    display: none;
}
</style>

<template>
    <div class="toaster"
         :class="{ hidden: state !== 'showing' }" >
        <Toast v-for="item in items"
               :key="item.id"
               :data="item"
               :type="item.type"
               @remove="send({type: 'remove', item})"
        />
    </div>
</template>

