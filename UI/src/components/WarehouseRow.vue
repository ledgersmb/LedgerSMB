<template>
    <tr>
        <td v-for="column in columns">
            <input
                :type="column.type"
                :value="props.data[column.key]"
                :name="column.key"
                :readonly="!editing || !editable"
                @input="(e) => emit('update', { key: column.key, value: e.target.value })"
                style="background-color:transparent"
                :class="editing ? 'editing':'neutral'"
            />
        </td>
        <td>
            <template v-if="props.type === 'existing'">
                <button :disabled="!editable || editing"
                        @click="emit('edit')">{{$t('Edit')}}</button>
                <button :disabled="!editable || !editing"
                        @click="emit('save')">{{$t('Save')}}</button>
                <button :disabled="!editable || !editing"
                        @click="emit('cancel')">{{$t('Cancel')}}</button>
                <button :disabled="!editable || editing"
                        @click="emit('delete')">{{$t('Delete')}}</button>
            </template>
            <button v-else
                    :disabled="!editable || !editing"
                    @click="emit('add')">{{$t('Add')}}</button>
        </td>
    </tr>
</template>

<style local>
.neutral {
    border-color: transparent;
}
</style>

<script setup>

const props = defineProps(["columns", "data", "editable", "editing", "type"]);
const emit = defineEmits(["edit", "cancel", "save", "delete", "update", "add"]);

</script>
