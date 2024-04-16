<!-- @format -->

<script>
import ImportCSVBase from "@/components/ImportCSV-Base";

export default {
    components: {
        "import-csv": ImportCSVBase
    },
    data() {
        return {
            type: "chart"
        };
    }
};
</script>

<template>
    <div id="import-chart">
        <import-csv :type="type" :transactionFields="false">
            <template #title> Import Chart of Accounts </template>
            <template #info>
                The uploaded file contains one account or heading per line.
            </template>
            <template #default>
                The following fields are expected (in this order):

                <dl>
                    <dt>accno</dt>
                    <dd />
                    <dt>description</dt>
                    <dd />
                    <dt>charttype</dt>
                    <dd />
                    <dt>category</dt>
                    <dd />
                    <dt>contra</dt>
                    <dd />
                    <dt>tax</dt>
                    <dd />
                    <dt>link</dt>
                    <dd />
                    <dt>heading</dt>
                    <dd />
                    <dt>gifi_accno</dt>
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
