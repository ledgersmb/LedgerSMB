<!-- @format -->

<script>
import ImportCSVBase from "@/components/ImportCSV-Base";

export default {
    components: {
        "import-csv": ImportCSVBase
    },
    data() {
        return {
            multi: true,
            type: "gl_multi"
        };
    }
};
</script>

<template>
    <div id="import-gl-batch">
        <import-csv :type="type" :multi="multi">
            <template #title> Import GL transaction batch </template>
            <template #info>
                The uploaded file contains the details of all transactions; the
                batch data is entered into the fields below.
            </template>
            <template #default>
                The first row of the file contains the field names; each
                following row will be transformed into a transaction of two
                lines. The following fields are expected (in this order):

                <dl>
                    <dt>debit_accno</dt>
                    <dd />
                    <dt>credit_accno</dt>
                    <dd />
                    <dt>amount</dt>
                    <dd />
                    <dt>curr</dt>
                    <dd />
                    <dt>amount_fx</dt>
                    <dd />
                    <dt>reference</dt>
                    <dd />
                    <dt>transdate</dt>
                    <dd />
                    <dt>description</dt>
                    <dd />
                    <dt>source_debit</dt>
                    <dd />
                    <dt>source_credit</dt>
                    <dd />
                    <dt>memo</dt>
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
