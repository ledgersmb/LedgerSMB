<script setup>

import { createToastMachine } from "./Toaster.machines";

const props = defineProps({"data": { }, "type": { default: "success" }});
const emit = defineEmits(["remove"]);

const title = props.data.title || "Title";
const text = props.data.text;

const { send } = createToastMachine(
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

<template>
    <div class="toast dijitContentPane dijitBorderContainer-child edgePanel"
         :class="type"
         @click="send('dismiss')">
        <div class="title" >{{ title }}</div>
        <div v-if="text">{{ text }}</div>
    </div>
</template>
