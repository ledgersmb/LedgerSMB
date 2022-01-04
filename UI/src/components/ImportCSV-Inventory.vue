<template>
   <div :id="'import-inventory-' + (multi ? 'batch' : 'single')">
      <import-csv :type="type" :multi="multi">
        <template v-slot:title>Import inventory <span v-if="multi">batch</span></template>
        <template v-slot:info>The uploaded file contains one inventory count
          for one stocked item per line. From the counts, adjustments will
          be calculated.</template>
        <template v-slot:default>
           The following fields are expected (in this order):

           <dl>
             <template v-if="multi">
               <dt>date</dt>
               <dd></dd>
             </template>
             <dt>partnumber</dt>
             <dd></dd>
             <dt>onhand</dt>
             <dd></dd>
             <dt>purchase_price</dt>
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
    props: ["multi"],
    data() {
       return {
          type: "inventory"
       };
    }
};
</script>
