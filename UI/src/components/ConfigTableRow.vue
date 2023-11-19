<script setup>

import { createRowMachine } from "@/components/ConfigTable.machines.js";
import { computed, inject, ref, watch } from "vue";
import { contextRef } from "@/robot-vue";
import { useI18n } from "vue-i18n";

const { t } = useI18n();

const props = defineProps([
    "defaultSelectable",
    "isDefault",
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
            "acquiring": (ctx, { dismissReceiver }) => {
                notify({
                    title: t("Getting latest data"),
                    type: "info",
                    dismissReceiver
                });
            },
            "adding": (ctx, { dismissReceiver }) => {
                notify({
                    title: t("Adding"),
                    type: "info",
                    dismissReceiver
                });
            },
            "added": () => { notify({ title: t("Added") }); },
            "deleting": (ctx, { dismissReceiver }) => {
                notify({
                    title: t("Deleting"),
                    type: "info",
                    dismissReceiver
                });
            },
            "deleted": () => { notify({ title: t("Deleted") }); },
            "saving": (ctx, { dismissReceiver }) => {
                notify({ title: t("Saving"), type: "info", dismissReceiver });
            },
            "saved": () => { notify({ title: t("Saved") }); },
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

let mouseOverDefault = ref(false);

async function setDefault() {
    let dismiss = () => {};
    notify({
        title: "Updating default language...",
        type: "info",
        dismissReceiver: (cb) => { dismiss = cb }
    });
    try {
        await props.store.setDefault(props.id);
    }
    catch {
        notify({ title: "Updated failed", type: "error" });
        return;
    }
    finally {
        dismiss();
    }
    notify({ title: "Updated default language" });
}

</script>

<template>
    <tr class="data-row">
        <td v-if="props.defaultSelectable"
            style="vertical-align:middle;text-align:center"
            @mouseover="mouseOverDefault = true"
            @mouseleave="mouseOverDefault = false">
            <template v-if="props.type !== 'existing'">
            </template>
            <template v-else-if="props.isDefault">
                <input
                    type="radio"
                    name="default"
                    :value="props.id"
                    :checked="props.isDefault" />
            </template>
            <template v-else>
                <input
                    v-show="!mouseOverDefault || !modifiable"
                    type="radio"
                    name="default"
                    :disabled="!modifiable"
                    :value="props.id"
                    :checked="props.isDefault" />
                <lsmb-button
                    v-show="mouseOverDefault && modifiable"
                    name="change-default"
                    @click="setDefault()">
                    Set
                </lsmb-button>
            </template>
        </td>
        <td v-for="column in columns"
            :key="column.key"
            class="data-entry">
            <input
                :type="column.type"
                :value="data[column.key]"
                :name="column.key"
                :readonly="!editing"
                :class="editing ? 'editing':'neutral'"
                class="input-box"
                @input="(e) => send({ type: 'update', key: column.key, value: e.target.value })"
            />
        </td>
        <td>
            <template v-if="props.type === 'existing'">
                <lsmb-button :disabled="!modifiable" name="modify"
                        @click="send('modify')">{{$t('Modify')}}</lsmb-button>
                <lsmb-button :disabled="!editing" name="save"
                        @click="send('save')">{{$t('Save')}}</lsmb-button>
                <lsmb-button :disabled="!editing" name="cancel"
                        @click="send('cancel')">{{$t('Cancel')}}</lsmb-button>
                <lsmb-button
                    v-if="props.deletable" name="delete"
                    :disabled="!editing"
                    @click="send('delete')">{{$t('Delete')}}</lsmb-button>
            </template>
            <lsmb-button v-if="props.type === 'new'" name="add"
                    :disabled="state !== 'idle'"
                    @click="send('add')">{{$t('Add')}}</lsmb-button>
        </td>
    </tr>
</template>
