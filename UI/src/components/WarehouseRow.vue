<template>
    <tr>
        <td v-for="column in columns"
            class="data-entry">
            <input
                :type="column.type"
                :value="data[column.key]"
                :name="column.key"
                :readonly="!editing"
                @input="(e) => send({ type: 'update', key: column.key, value: e.target.value })"
                :class="editing ? 'editing':'neutral'"
                class="input-box"
            />
        </td>
        <td>
            <template v-if="props.type === 'existing'">
                <lsmb-button :disabled="!modifiable"
                        @click="send('modify')">{{$t('Modify')}}</lsmb-button>
                <lsmb-button :disabled="!editing"
                        @click="send('save')">{{$t('Save')}}</lsmb-button>
                <lsmb-button :disabled="!editing"
                        @click="send('cancel')">{{$t('Cancel')}}</lsmb-button>
                <lsmb-button
                    v-if="props.deletable"
                    :disabled="!editing"
                    @click="send('delete')">{{$t('Delete')}}</lsmb-button>
            </template>
            <lsmb-button v-else
                    :disabled="state !== 'idle'"
                    @click="send('add')">{{$t('Add')}}</lsmb-button>
        </td>
    </tr>
</template>

<style local>
.data-entry {
    vertical-align: middle;
    padding: 0.1em 0.5ex;
}
.input-box {
    box-sizing: border-box;
    padding: 0.1em 0.3ex;
    width: 100%;
}
.neutral {
    border-color: transparent;
    background-color: transparent;
}
.editing {
    background-color: white;
    border-color: black;
}
</style>

<script setup>

import { createWarehouseMachine } from "./Warehouses.machines.js";
import { computed, inject, watch } from "vue";
import { contextRef } from "@/robot-vue";

const props = defineProps(["columns", "id", "editingId", "type", "deletable"]);
const emit = defineEmits(["modifying", "idle"]);
const warehousesStore = inject("configStore");
const notify = inject("notify");

const { service, send, state } = createWarehouseMachine(warehousesStore, {
    ctx: {
        rowId: props.id,
        adding: props.type === "new",
        notifications: {
            "acquiring": (ctx, cb) => {
                notify({
                    title: "Getting latest data",
                    type: "info",
                    dismissReceiver: cb
                });
            },
            "adding": (ctx, cb) => {
                notify({ title: "Adding", type: "info", dismissReceiver: cb });
            },
            "added": (ctx) => { notify({ title: "Added" }); },
            "deleting": (ctx, cb) => {
                notify({ title: "Deleting", type: "info", dismissReceiver: cb });
            },
            "deleted": (ctx) => { notify({ title: "Deleted" }); },
            "saving": (ctx, cb) => {
                notify({ title: "Saving", type: "info", dismissReceiver: cb });
            },
            "saved": (ctx) => { notify({ title: "Saved" }); },
        }
    },
    cb: {
        error: () => {
            notify({ title: "Failed", type: "error" });
            send("restart");
        },
        modifying: () => emit("modifying"),
        idle: () => emit("idle")
    }
});
const data = contextRef(service, "data");
const editing = computed(
    () => (state.value === "modifying" || props.type === "new")
);
const modifiable = computed(() => state.value === "idle");

watch(() => props.editingId,
      (newValue) => {
          if (! newValue) {
              // ignored when not applicable to the current state
              // meaning: ignored when we're the cause of this value-change
              send("enable");
          }
          else if (newValue !== props.id) {
              send('disable');
          }
      }
);

</script>
