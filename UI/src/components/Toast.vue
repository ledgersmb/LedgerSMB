<script setup>

import { createToastMachine } from "@/components/Toaster.machines";

const props = defineProps({"data": { }, "type": { default: "success" }});
const emit = defineEmits(["remove"]);

const title = props.data.title || "Title";
const text = props.data.text;
const duration = text ? 10 : 2;


const { send, state } = createToastMachine(
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
    window.setTimeout(() => { send('show') }, 250);
} else {
    send('show');
}

</script>

<template>
    <div class="toast dijitContentPane dijitBorderContainer-child edgePanel"
         :class="type"
         v-show="state !== 'pending'"
         @click="send('dismiss-immediate')"
         @mouseenter="send('hold')"
         @mouseleave="send('release')">
        <div class="title" >{{ title }}</div>
        <div v-if="text">{{ text }}</div>
    </div>
</template>
