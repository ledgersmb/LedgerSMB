<template>
    <div :id="type">
        <template v-if="heading">
            <div class="listtop"><slot name="title" /></div>
            <div class="info"><slot name="info" /></div>
        </template>
        <form name="csvupload">
            <input type="hidden" name="type" :value="type">
            <div v-if="multi"
                 class="listheading">Batch Information</div>
            <div :class="transaction_fields ? 'two-column-grid' : 'non-grid'"
                 style="width:fit-content;grid-gap:4px">
                <template v-if="transaction_fields">
                    <lsmb-text class="reference"
                               name="reference"
                               title="Reference"
                               value=""
                               size="15"
                               @input="status=null" />
                    <lsmb-text class="description"
                               name="description"
                               title="Description"
                               value=""
                               required
                               @input="status=null" />
                    <lsmb-date title="Transaction Date"
                               name="transdate"
                               size="12"
                               required
                               @change="status=null" />
                </template>
                <lsmb-file name="import_file"
                           label="From File"
                           accept=".csv"
                           required
                           @change="status=null" />
            </div>
            <div class="inputrow"
                 :class="transaction_fields ? '' : 'non-grid'"
                 id="buttonrow" >
                <input type="hidden" name="trans_type" />
                <lsmb-button class="submit"
                             name="action" @click="upload">{{ "Save" }}</lsmb-button>
            </div>
            <div v-show="status!==null" :class='status ? "success" : "failure"'>
                {{ message }}
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


<script>

export default {
    data() {
       return {
          message: "",
          status: null
       };
    },
    methods: {
       async upload() {
          let data = new FormData(document.forms.csvupload);
          data.append("action", "run_import");

          let r = await fetch("import_csv.pl", {
             method: "POST",
             body: data,
             headers: new Headers({
                "X-Requested-With": "XMLHttpRequest"
             })
          });

          if (r.ok) {
             document.forms.csvupload.reset();
             this.message = "Upload succeeded";
             this.status = true;
          } else {
             this.message = await r.text();
             this.status = false;
          }
       }
    },
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
};
</script>
