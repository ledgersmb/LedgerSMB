<script setup>

import { createToastMachine } from "./Toaster.machines";

const props = defineProps({"data": { }, "type": { default: "success" }});
const emit = defineEmits(["remove"]);

const title = props.data.title || "Title";
const text = props.data.text;
const duration = text ? 10 : 2;


const { send } = createToastMachine(
    {
        item: props.data
    },
    {
        cb: {
            removed: () => { emit("remove", { item: props.data }) }
        }
    });

window.setTimeout(() => { send('dismiss') }, duration * 1000);
if (props.data.dismissReceiver) {
    props.data.dismissReceiver( () => send('dismiss') );
}

</script>

<template>
    <div class="toast dijitContentPane dijitBorderContainer-child edgePanel"
         :class="type"
         @click="send('dismiss-immediate')"
         @mouseenter="send('hold')"
         @mouseleave="send('release')">
        <div class="title" >{{ title }}</div>
        <div v-if="text">{{ text }}</div>
    </div>
</template>
