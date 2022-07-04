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
            <lsmb-button v-if="props.type === 'new'"
                    :disabled="state !== 'idle'"
                    @click="send('add')">{{$t('Add')}}</lsmb-button>
        </td>
    </tr>
</template>

<script setup>

import { createRowMachine } from "./ConfigTable.machines.js";
import { computed, inject, watch } from "vue";
import { contextRef } from "@/robot-vue";
import { useI18n } from "vue-i18n";

const { t } = useI18n();

const props = defineProps([
    "columns",
    "deletable",
    "editingId",
    "id",
    "store",
    "type"
]);
const emit = defineEmits(["modifying", "idle"]);
const notify = inject("notify");

const { service, send, state } = createRowMachine(props.store, {
    ctx: {
        rowId: props.id,
        adding: props.type === "new",
        notifications: {
            "acquiring": (ctx, cb) => {
                notify({
                    title: t("Getting latest data"),
                    type: "info",
                    dismissReceiver: cb
                });
            },
            "adding": (ctx, cb) => {
                notify({
                    title: t("Adding"),
                    type: "info",
                    dismissReceiver: cb
                });
            },
            "added": (ctx) => { notify({ title: t("Added") }); },
            "deleting": (ctx, cb) => {
                notify({
                    title: t("Deleting"),
                    type: "info",
                    dismissReceiver: cb
                });
            },
            "deleted": (ctx) => { notify({ title: t("Deleted") }); },
            "saving": (ctx, cb) => {
                notify({ title: t("Saving"), type: "info", dismissReceiver: cb });
            },
            "saved": (ctx) => { notify({ title: t("Saved") }); },
        }
    },
    cb: {
        error: () => {
            notify({ title: t("Failed"), type: "error" });
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
