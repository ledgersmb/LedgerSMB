<script>

import ImportCSVBase from "@/components/ImportCSV-Base";


export default {
    components: {
       "import-csv": ImportCSVBase
    },
    data() {
       return {
          multi: true,
          type: 'timecard'
       };
    }
};
</script>

<template>
   <div id="import-timecard">
      <import-csv :type="type">
        <template #title>Import timecards</template>
        <template #info>The uploaded file contains one timecard per row;
             as there is no functionality to put timecards into batches,\
             no header fields need to be entered below.</template>
        <template #default>
           The following fields are expected (in this order):

           <dl>
             <dt>employee</dt>
             <dd></dd>
             <dt>business_unit_id</dt>
             <dd></dd>
             <dt>transdate</dt>
             <dd></dd>
             <dt>partnumber</dt>
             <dd></dd>
             <dt>description</dt>
             <dd></dd>
             <dt>qty</dt>
             <dd></dd>
             <dt>non_billable</dt>
             <dd></dd>
             <dt>sellprice</dt>
             <dd></dd>
             <dt>allocated</dt>
             <dd></dd>
             <dt>notes</dt>
             <dd></dd>
             <dt>jctype</dt>
             <dd></dd>
             <dt>curr</dt>
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
