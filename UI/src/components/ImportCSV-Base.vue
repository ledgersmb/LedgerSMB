<script>
import { ref, inject } from "vue";
import { useI18n } from "vue-i18n";
import { createImportMachine } from "./ImportCSV-Base.machines.js";

export default {
    props: {
        "multi": {},
        "type": {},
        "heading": {
            "default": true
        },
        "transaction_fields": {
            default: true
        }
    },
    setup() {
        const { t } = useI18n();
        let notify = inject("notify");
        let form = ref(null);
        let { service, state } = createImportMachine({
            form,
            notifications: {
                "submitting": (ctx, { dismissReceiver }) => {
                    notify({
                        title: t("Uploading CSV..."),
                        type: "info",
                        dismissReceiver
                    });
                },
                "success": () => { notify({ title: t("Uploaded") }); },
                "submitError": (ctx, { event }) => {
                    notify({
                        title: t("Failure sending CSV"),
                        text: event.error,
                        type: "error"
                    });
                },
                "processingError": (ctx, { event }) => {
                    notify({
                        title: t("Failure processing CSV"),
                        text: event.data.error,
                        type: "error"
                    });
                },
                "responseError": (ctx, { event }) => {
                    notify({
                        title: t("Failed to process server response"),
                        text: event.error,
                        type: "error"
                    });
                }
            },
        });
        return {
            form, notify, state,
            machine: service,
            message: "",
        };
    },
};
</script>

<template>
    <div :id="type">
        <template v-if="heading">
            <div class="listtop"><slot name="title" /></div>
            <div class="info"><slot name="info" /></div>
        </template>
        <form ref="form" name="csvupload">
            <input type="hidden" name="type" :value="type">
            <div v-if="multi"
                 class="listheading">Batch Information</div>
            <div :class="transaction_fields ? 'two-column-grid' : 'non-grid'"
                 style="width:fit-content">
                <template v-if="transaction_fields">
                    <lsmb-text class="reference"
                               name="reference"
                               label="Reference"
                               value=""
                               size="15"
                               @input="machine.send('input')" />
                    <lsmb-text class="description"
                               name="description"
                               label="Description"
                               value=""
                               required
                               @input="machine.send('input')" />
                    <lsmb-date label="Transaction Date"
                               name="transdate"
                               size="12"
                               required
                               @input="machine.send('input')"
                               @change="machine.send('input')" />
                </template>
                <lsmb-file name="import_file"
                           label="From File"
                           accept=".csv"
                           required
                           @input="machine.send('input')"
                           @change="machine.send('input')" />
            </div>
            <div id="buttonrow"
                 class="inputrow"
                 :class="transaction_fields ? '' : 'non-grid'" >
                <input type="hidden" name="trans_type" />
                <lsmb-button
                    class="submit"
                    name="action"
                    :disabled="state !== 'ready'"
                    @click="machine.send('submit')"
                >{{ "Save" }}</lsmb-button>
            </div>
            <div class="details">
                <slot />
            </div>
        </form>
    </div>
</template>


<style scoped>

.failure {
   background-color: red;
   color: white;
   font-weight: bold;
   text-align: center;
}

.success {
   background-color: dark-green;
   text-align: center;
}

.non-grid {
    display: inline-block;
}

.non-grid label {
    margin-right: 2ex;
}

.details {
    margin-top: 1.5em;
}

</style>
