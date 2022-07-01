<script setup>

import { contextRef } from "@/robot-vue";
import { createToastMachine } from "./Toaster.machines";

const props = defineProps({"data": { }, "type": { default: "success" }});
const emit = defineEmits(["remove"]);

const title = props.data.title || "Title";
const text = props.data.text;

const { service, send, state } = createToastMachine(
    {
        item: props.data,
        duration: text ? "long" : "short"
    },
    {
        cb: {
            removed: () => { emit("remove", { item: props.data }) }
        }
    });

if (props.data.dismissReceiver) {
    props.data.dismissReceiver( () => send('dismiss') );
}

</script>



<style local>
.toast.dijitBorderContainerPane {
    width:100%;
    text-align:center;
    box-shadow: 6px 6px 6px lightgray;
    box-sizing: border-box;
    overflow: hidden;
    overflow-wrap: normal;
    position: relative !important;
    margin: 1ex 0;
}

.toast.error {
    background: linear-gradient(to right bottom, #d88, #eaa);
}

.toast.success {
    background: linear-gradient(to right bottom, #8d8, #fff);
}

.toast.info {
    background: linear-gradient(to right bottom, #bcd8f4, #fff);
}

.title {
    font-weight: bold;
}

</style>

<template>
    <div class="toast dijitContentPane dijitBorderContainerPane dijitBorderContainer-child edgePanel"
         :class="type"
         @click="send('dismiss')">
        <div class="title" >{{ title }}</div>
        <div v-if="text">{{ text }}</div>
    </div>
</template>
