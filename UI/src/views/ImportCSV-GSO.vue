<!-- @format -->

<script>
import ImportCSVBase from "@/components/ImportCSV-Base";

export default {
    components: {
        "import-csv": ImportCSVBase
    },
    props: ["multi", "type"],
    data() {
        return {};
    }
};
</script>

<template>
    <div :id="'import-' + type">
        <import-csv :type="type" :transactionFields="false">
            <template #title> Import {{ type }} </template>
            <template #info>
                The uploaded file contains one {{ type }} item header fields
                need to be entered below.
            </template>
            <template #default>
                The following fields are expected (in this order):

                <dl>
                    <dt>partnumber</dt>
                    <dd />
                    <dt>description</dt>
                    <dd />
                    <dt>unit</dt>
                    <dd />
                    <dt>listprice</dt>
                    <dd />
                    <dt>sellprice</dt>
                    <dd />
                    <dt>lastcost</dt>
                    <dd />
                    <template v-if="type === 'goods'">
                        <dt>weight</dt>
                        <dd />
                    </template>
                    <dt>notes</dt>
                    <dd />
                    <template v-if="type === 'goods'">
                        <dt>makemodel</dt>
                        <dd />
                        <dt>assembly</dt>
                        <dd />
                        <dt>alternate</dt>
                        <dd />
                        <dt>rop</dt>
                        <dd />
                    </template>
                    <template v-if="type === 'goods' || type === 'overhead'">
                        <dt>inventory_accno</dt>
                        <dd />
                    </template>
                    <template v-if="type !== 'overhead'">
                        <dt>income_accno</dt>
                        <dd />
                    </template>
                    <dt>expense_accno</dt>
                    <dd />
                    <template v-if="type === 'goods'">
                        <dt>returns_accno</dt>
                        <dd />
                        <dt>bin</dt>
                        <dd />
                    </template>
                    <template v-if="type === 'goods' || type === 'overhead'">
                        <dt>bom</dt>
                        <dd />
                    </template>
                    <template v-if="type === 'goods'">
                        <dt>image</dt>
                        <dd />
                        <dt>drawing</dt>
                        <dd />
                        <dt>microfiche</dt>
                        <dd />
                    </template>
                    <dt>partsgroup</dt>
                    <dd />
                    <template v-if="type === 'goods'">
                        <dt>avgcost</dt>
                        <dd />
                    </template>
                    <dt>taxaccnos</dt>
                    <dd />
                </dl>
            </template>
        </import-csv>
    </div>
</template>

<style scoped>
dl > dt {
    font-weight: bold;
    margin-left: 2em;
}

dl > dd {
    margin-left: 4em;
}
</style>
