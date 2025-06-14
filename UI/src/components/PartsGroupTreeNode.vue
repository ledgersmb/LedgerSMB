<!-- @format -->

<script setup>
import { computed, ref } from "vue";
import {
    QBtn,
    //    QExpansionItem,
    QIcon,
    QInput,
    QItem,
    QItemLabel,
    QItemSection,
    QTooltip
} from "quasar";

const props = defineProps({
    node: {
        type: Object,
        required: true
    },
    canCancelSave: {
        type: Boolean,
        required: false,
        default: true
    },
    isNewNode: {
        type: Boolean,
        required: false,
        default: false
    }
});

const emit = defineEmits([
    "start-edit",
    "cancel-edit",
    "update-node",
    "add-child",
    "delete-node"
]);

const expanded = ref(false);
const editingText = ref("");
//const editingLang = ref("");
const isEditing = ref(props.isNewNode);
//const isEditingLang = ref("");
const isAddingChild = ref(false);

const startAddChild = () => {
    isAddingChild.value = true;
    updateExpanded(true);
};
const cancelAddChild = () => {
    isAddingChild.value = false;
    expanded.value = hasChildren.value;
};

const addChild = (id, updates) => {
    isAddingChild.value = false;
    emit("add-child", props.node.id, {
        description: updates.description
    });
};

const startEdit = () => {
    isEditing.value = true;
    editingText.value = props.node.description;
    emit("start-edit");
};

/* const startEditLang = (lang) => {
 *     isEditingLang.value = lang;
 *     if (props.node.languages) {
 *         editingLang.value = props.node.languages[lang];
 *     } else {
 *         editingLang.value = "";
 *     }
 * };
 *  */
const saveEdit = () => {
    if (editingText.value.trim()) {
        emit("update-node", props.node.id, {
            description: editingText.value.trim()
        });
    }
    isEditing.value = props.isNewNode;
    editingText.value = "";
};

/* const saveEditLang = (value) => {
 *     props.node.languages[isEditingLang.value] = value;
 *     isEditingLang.value = "";
 *     editingLang.value = "";
 * };
 *  */
const cancelEdit = () => {
    isEditing.value = false;
    editingText.value = "";
    emit("cancel-edit");
};

/* const cancelEditLang = () => {
 *     isEditingLang.value = "";
 *     editingLang.value = "";
 * };
 *  */

const deleteNode = () => {
    emit("delete-node", props.node.id);
};

const updateChildNode = (nodeId, updates) => {
    emit("update-node", nodeId, updates);
};

const deleteChildNode = (nodeId) => {
    emit("delete-node", nodeId);
};

const hasChildren = computed(() => {
    return props.node.children && props.node.children.length > 0;
});

const updateExpanded = (val) => {
    expanded.value = val;
};
</script>

<template>
    <li role="treeitem">
        <q-item dense>
            <q-item-section
                dense
                tabindex="0"
                @keyup.enter="updateExpanded(!expanded)"
            >
                <div class="row items-center">
                    <div v-if="!isEditing" class="col">
                        <q-item dense>
                            <!-- required for languages support
                        <q-expansion-item
                            dense
                            dense-toggle
                            expand-separator
                            expand-icon-toggle
                            toggle-aria-label="Translations"
                        >
                            <template #header>-->
                            <q-item-section>
                                <q-item-label>
                                    <q-icon
                                        v-if="expanded"
                                        name="mdi-menu-down"
                                        size="sm"
                                        @click="updateExpanded(!expanded)"
                                    >
                                        <q-tooltip>Collapse</q-tooltip>
                                    </q-icon>
                                    <q-icon
                                        v-else
                                        :class="{ invisible: !hasChildren }"
                                        name="mdi-menu-right"
                                        size="sm"
                                        @click="updateExpanded(!expanded)"
                                    >
                                        <q-tooltip>Expand</q-tooltip>
                                    </q-icon>
                                    {{ node.description }}
                                </q-item-label>
                            </q-item-section>
                            <q-item-section dense side>
                                <div class="row q-gutter-xs">
                                    <q-btn
                                        flat
                                        dense
                                        round
                                        icon="mdi-pencil-outline"
                                        color="primary"
                                        size="sm"
                                        @click.stop="startEdit"
                                    >
                                        <q-tooltip>{{ $t("Edit") }}</q-tooltip>
                                    </q-btn>
                                    <q-btn
                                        flat
                                        dense
                                        round
                                        icon="mdi-plus-circle-outline"
                                        color="green"
                                        size="sm"
                                        @click.stop="startAddChild"
                                    >
                                        <q-tooltip>{{
                                            $t("Add child")
                                        }}</q-tooltip>
                                    </q-btn>
                                    <q-btn
                                        flat
                                        dense
                                        round
                                        disabled
                                        icon="mdi-delete"
                                        color="red"
                                        size="sm"
                                        @click.stop="deleteNode"
                                    >
                                        <q-tooltip>{{
                                            $t("Delete")
                                        }}</q-tooltip>
                                    </q-btn>
                                </div>
                            </q-item-section>
                            <!-- required for languages support
                            </template>
                            <template #default>
                                <table style="margin-left: 3em">
                                    <thead>
                                        <tr>
                                            <th>Language</th>
                                            <th>Translation</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr
                                            v-for="(
                                                value, key
                                            ) in node.languages"
                                            :key="key"
                                        >
                                            <td>{{ key }}</td>
                                            <td>
                                                <lsmb-text
                                                    v-if="isEditingLang == key"
                                                    :value="editingLang.value"
                                                    type="text"
                                                    name="lang"
                                                    @keyup.esc="cancelEditLang"
                                                    @keyup.enter="
                                                        saveEditLang(this.value)
                                                    "
                                                ></lsmb-text>
                                                <template v-else>
                                                    {{ value }}
                                                </template>
                                            </td>
                                            <td>
                                                <q-btn
                                                    flat
                                                    dense
                                                    round
                                                    icon="mdi-pencil-outline"
                                                    color="primary"
                                                    size="sm"
                                                    @click="() => { startEditLang(key) }"
                                                >
                                                    <q-tooltip>Edit</q-tooltip>
                                                </q-btn>
                                                <q-btn
                                                    flat
                                                    dense
                                                    round
                                                    disabled
                                                    icon="mdi-delete"
                                                    color="red"
                                                    size="sm"
                                                >
                                                    <q-tooltip
                                                    >Delete</q-tooltip
                                                    >
                                                </q-btn>
                                            </td>
                                        </tr>
                                    </tbody>
                                    <tfoot>
                                        <tr>
                                            <td>
                                                < !-- TODO! this really should be a selection -- >
                                                <lsmb-text
                                                    name="lang"
                                                    style="width: 100%"
                                                ></lsmb-text>
                                            </td>
                                            <td>
                                                <lsmb-text
                                                    name="trans"
                                                    style="width: 100%"
                                                ></lsmb-text>
                                            </td>
                                            <td>
                                                <q-btn
                                                    flat
                                                    dense
                                                    round
                                                    icon="mdi-check"
                                                    color="green"
                                                    size="sm"
                                                >
                                                    <q-tooltip>Add</q-tooltip>
                                                </q-btn>
                                            </td>
                                        </tr>
                                    </tfoot>
                                </table>
                            </template>
                        </q-expansion-item>-->
                        </q-item>
                    </div>
                    <q-item v-else dense class="q-gutter-sm col">
                        <q-item-section dense>
                            <q-input
                                v-model="editingText"
                                dense
                                outlined
                                autofocus
                                @keyup.enter="saveEdit"
                                @keyup.escape="cancelEdit"
                                @click.stop
                            />
                        </q-item-section>
                        <q-item-section dense side>
                            <div class="q-gutter-xs row">
                                <q-btn
                                    flat
                                    dense
                                    round
                                    icon="mdi-check"
                                    color="green"
                                    size="sm"
                                    @click.stop="saveEdit"
                                >
                                    <q-tooltip>{{ $t("Save") }}</q-tooltip>
                                </q-btn>
                                <q-btn
                                    flat
                                    dense
                                    round
                                    :disabled="!canCancelSave"
                                    icon="mdi-close"
                                    color="red"
                                    size="sm"
                                    @click.stop="cancelEdit"
                                >
                                    <q-tooltip>{{ $t("Cancel") }}</q-tooltip>
                                </q-btn>
                            </div>
                        </q-item-section>
                    </q-item>
                </div>
            </q-item-section>
        </q-item>

        <div v-if="expanded && (hasChildren || isAddingChild)">
            <ul class="hierarchy-node-list" role="group">
                <template v-if="hasChildren">
                    <parts-group-tree-node
                        v-for="child in node.children"
                        :key="child.id"
                        :node="child"
                        @update-node="updateChildNode"
                        @add-child="startAddChild"
                        @delete-node="deleteChildNode"
                    />
                </template>
                <parts-group-tree-node
                    v-if="isAddingChild"
                    is-new-node
                    :node="{}"
                    @update-node="addChild"
                    @cancel-edit="cancelAddChild"
                />
            </ul>
        </div>
    </li>
</template>

<style>
.q-item {
    padding: 4px 8px;
    min-height: 2em;
}
.hierarchy-node-list {
    list-style-type: none;
    padding-left: 3ex;
}
.invisible {
    visibility: invisible;
}
</style>
