<template>
   <div id="import-chart">
      <import-csv :type="type">
        <template v-slot:title>Import Chart of Accounts
        </template>
        <template v-slot:info>
           The uploaded file contains one account or heading per line.
        </template>
        <template v-slot:default>
           The following fields are expected (in this order):

           <dl>
             <dt>accno</dt>
             <dd></dd>
             <dt>description</dt>
             <dd></dd>
             <dt>charttype</dt>
             <dd></dd>
             <dt>category</dt>
             <dd></dd>
             <dt>contra</dt>
             <dd></dd>
             <dt>tax</dt>
             <dd></dd>
             <dt>link</dt>
             <dd></dd>
             <dt>heading</dt>
             <dd></dd>
             <dt>gifi_accno</dt>
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
          type: "chart"
       };
    }
};
</script>
