<!-- @format -->

<script>
import ImportCSVBase from "@/components/ImportCSV-Base";

export default {
    components: {
        "import-csv": ImportCSVBase
    },
    props: ["multi"],
    data() {
        return {
            type: "inventory"
        };
    }
};
</script>

<template>
    <div :id="'import-inventory-' + (multi ? 'batch' : 'single')">
        <import-csv :type="type" :multi="multi">
            <template #title>
                Import inventory <span v-if="multi">batch</span>
            </template>
            <template #info>
                The uploaded file contains one inventory count for one stocked
                item per line. From the counts, adjustments will be calculated.
            </template>
            <template #default>
                The following fields are expected (in this order):

                <dl>
                    <template v-if="multi">
                        <dt>date</dt>
                        <dd />
                    </template>
                    <dt>partnumber</dt>
                    <dd />
                    <dt>onhand</dt>
                    <dd />
                    <dt>purchase_price</dt>
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
