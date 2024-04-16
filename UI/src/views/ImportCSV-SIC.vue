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
    <div id="import-sic">
        <import-csv
            type="sic"
            :heading="false"
            :transactionFields="false"
            @upload-success="$emit('upload-success')"
            @upload-error="$emit('upload-error')"
        >
            <template #title>
                > Import
                <abbr title="Standard Industrial Classification">SIC</abbr>
                codes
            </template>
            <template #info>
                The uploaded file contains one SIC code per line.
            </template>
            <template #default>
                The following fields are expected (in this order):
                <dl>
                    <dt>code</dt>
                    <dd />
                    <dt>sictype</dt>
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
