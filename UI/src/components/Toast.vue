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

if (props.data.dismissReceiver) {
    props.data.dismissReceiver( () => send('dismiss') );
    window.setTimeout(() => { send('show') }, 250);
} else {
    send('show');
    window.setTimeout(() => { send('dismiss') }, duration * 1000);
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
        <div v-if="text" style="margin-top:1em">{{ text }}</div>
    </div>
</template>
