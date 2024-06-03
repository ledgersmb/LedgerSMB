<!-- @format -->

<script>
import ImportCSVBase from "@/components/ImportCSV-Base";

export default {
    components: {
        "import-csv": ImportCSVBase
    },
    emits: ["upload-success", "upload-error"],
    data() {
        return {};
    }
};
</script>

<template>
    <div id="import-gifi">
        <import-csv
            type="gifi"
            :heading="false"
            :transactionFields="false"
            @upload-success="$emit('upload-success')"
            @upload-error="$emit('upload-error')"
        >
            <template #title>
                Import
                <abbr title="General Index of Financial Information">GIFI</abbr>
                codes
            </template>
            <template #info>
                The uploaded file contains one GIFI code per line.
            </template>
            <template #default>
                The following fields are expected (in this order):
                <dl>
                    <dt>accno</dt>
                    <dd />
                    <dt>description</dt>
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
