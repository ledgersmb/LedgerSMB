<template>
    <tr>
        <td v-for="column in columns"
            class="data-entry">
            <input
                :type="column.type"
                :value="props.data[column.key]"
                :name="column.key"
                :readonly="!editing || !editable"
                @input="(e) => emit('update', { key: column.key, value: e.target.value })"
                :class="editing ? 'editing':'neutral'"
                class="input-box"
            />
        </td>
        <td>
            <template v-if="props.type === 'existing'">
                <lsmb-button :disabled="!editable || editing"
                        @click="emit('edit')">{{$t('Edit')}}</lsmb-button>
                <lsmb-button :disabled="!editable || !editing"
                        @click="emit('save')">{{$t('Save')}}</lsmb-button>
                <lsmb-button :disabled="!editable || !editing"
                        @click="emit('cancel')">{{$t('Cancel')}}</lsmb-button>
                <lsmb-button :disabled="!editable || editing"
                        @click="emit('delete')">{{$t('Delete')}}</lsmb-button>
            </template>
            <lsmb-button v-else
                    :disabled="!editable || !editing"
                    @click="emit('add')">{{$t('Add')}}</lsmb-button>
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

const props = defineProps(["columns", "data", "editable", "editing", "type"]);
const emit = defineEmits(["edit", "cancel", "save", "delete", "update", "add"]);

</script>
