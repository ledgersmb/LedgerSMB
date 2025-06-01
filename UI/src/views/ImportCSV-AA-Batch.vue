<script>

import ImportCSVBase from "@/components/ImportCSV-Base";


export default {
    components: {
       "import-csv": ImportCSVBase
    },
    props: ["type"],
    data() {
       return {
          multi: true
       };
    },
    computed: {
       counterparty_type() {
          return (this.type === "ar") ? "customer" : "vendor";
       },
       pnl_effect() {
          return (this.type === "ar") ? "income" : "expense";
       },
       module_name() {
          return this.type.toUpperCase();
       }
    }
};
</script>

<template>
   <div :id="'import-' + type + '-' + (multi ? 'batch' : 'single')">
      <import-csv :type="type" :multi="multi">
        <template #title>Import {{ module_name }} transaction batch</template>
        <template #info>The uploaded file contains the details of all
             transactions; the batch data is entered into the fields
             below.</template>
        <template #default>
           The first row of the file contains the field names; each following row
           will be transformed into a transaction with one {{ module_name }}
           and one {{ pnl_effect }} line. The following fields are expected
           (in this order):

           <dl>
              <dt>{{ counterparty_type }}</dt>
              <dd></dd>
              <dt>amount</dt>
              <dd></dd>
              <dt>curr</dt>
              <dd></dd>
              <dt>fx_rate</dt>
              <dd></dd>
              <dt>account</dt>
              <dd></dd>
              <dt>ap</dt>
              <dd></dd>
              <dt>description</dt>
              <dd></dd>
              <dt>invnumber</dt>
              <dd></dd>
              <dt>transdate</dt>
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
