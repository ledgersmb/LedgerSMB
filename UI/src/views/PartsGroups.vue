<!-- @format -->

<script setup>
import { ref } from "vue";
import PartsGroupTreeNode from "@/components/PartsGroupTreeNode";
import { usePartsgroupsStore } from "@/store/partsgroups";

const newRootNode = ref({});
const store = usePartsgroupsStore();
const initialized = ref(false);

store.initialize().then(() => {
    initialized.value = true;
});

const updateNode = (id, updates) => {
    if (updates.description) {
        store.save(id, { id: id, description: updates.description });
    }
};

const addChild = async (id, updates) => {
    await store.add({ parent: id, description: updates.description });
};

const deleteNode = (id) => {
    store.del(id);
};

const addRootGroup = async (id, updates) => {
    await store.add({ description: updates.description });
    newRootNode.value = {};
};
</script>

<template>
    <h1 class="listtop">{{ $t("Manage parts groups") }}</h1>
    <p v-if="!initialized">Loading...</p>
    <ul v-else class="root-hierarchy-node-list" role="tree">
        <parts-group-tree-node
            v-for="item in store.tree"
            :key="item.id"
            :node="item"
            @update-node="updateNode"
            @add-child="addChild"
            @delete-node="deleteNode"
        />
        <parts-group-tree-node
            is-new-node
            :canCancelSave="false"
            :node="newRootNode"
            @update-node="addRootGroup"
        />
    </ul>
</template>

<style>
.root-hierarchy-node-list {
    list-style-type: none;
    margin-left: 0;
    padding-left: 0;
}
</style>
