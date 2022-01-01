<template>
   <div id="import-gl-batch">
      <import-csv :type="type" :multi="multi">
        <template v-slot:title>Import GL transaction batch</template>
        <template v-slot:info>The uploaded file contains the details of all
             transactions; the batch data is entered into the fields
             below.</template>
        <template v-slot:default>
           The first row of the file contains the field names; each following row
           will be transformed into a transaction of two lines. The following fields are expected (in this order):

           <dl>
             <dt>debit_accno</dt>
             <dd></dd>
             <dt>credit_accno</dt>
             <dd></dd>
             <dt>amount</dt>
             <dd></dd>
             <dt>curr</dt>
             <dd></dd>
             <dt>amount_fx</dt>
             <dd></dd>
             <dt>reference</dt>
             <dd></dd>
             <dt>transdate</dt>
             <dd></dd>
             <dt>description</dt>
             <dd></dd>
             <dt>source_debit</dt>
             <dd></dd>
             <dt>source_credit</dt>
             <dd></dd>
             <dt>memo</dt>
             <dd></dd>
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

<script>

import ImportCSVBase from "./ImportCSV-Base";


export default {
    components: {
       "import-csv": ImportCSVBase
    },
    data() {
       return {
          multi: true,
          type: 'gl'
       };
    }
};
</script>
