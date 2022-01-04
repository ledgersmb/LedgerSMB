<template>
   <div :id="'import-' + type">
      <import-csv :type="type">
        <template v-slot:title>Import {{ type }}</template>
        <template v-slot:info>The uploaded file contains one {{ type }} item
             per row; no header fields need to be entered below.</template>
        <template v-slot:default>
           The following fields are expected (in this order):

           <dl>
             <dt>partnumber</dt>
             <dd></dd>
             <dt>description</dt>
             <dd></dd>
             <dt>unit</dt>
             <dd></dd>
             <dt>listprice</dt>
             <dd></dd>
             <dt>sellprice</dt>
             <dd></dd>
             <dt>lastcost</dt>
             <dd></dd>
             <template v-if="type === 'goods'">
                <dt>weight</dt>
                <dd></dd>
             </template>
             <dt>notes</dt>
             <dd></dd>
             <template v-if="type === 'goods'">
                <dt>makemodel</dt>
                <dd></dd>
                <dt>assembly</dt>
                <dd></dd>
                <dt>alternate</dt>
                <dd></dd>
                <dt>rop</dt>
                <dd></dd>
             </template>
             <template v-if="type === 'goods' || type === 'overhead'">
                <dt>inventory_accno</dt>
                <dd></dd>
             </template>
             <template v-if="type !== 'overhead'">
                <dt>income_accno</dt>
                <dd></dd>
             </template>
             <dt>expense_accno</dt>
             <dd></dd>
             <template v-if="type === 'goods'">
                <dt>returns_accno</dt>
                <dd></dd>
                <dt>bin</dt>
                <dd></dd>
             </template>
             <template v-if="type === 'goods' || type === 'overhead'">
                <dt>bom</dt>
                <dd></dd>
             </template>
             <template v-if="type === 'goods'">
                <dt>image</dt>
                <dd></dd>
                <dt>drawing</dt>
                <dd></dd>
                <dt>microfiche</dt>
                <dd></dd>
             </template>
             <dt>partsgroup</dt>
             <dd></dd>
             <template v-if="type === 'goods'">
                <dt>avgcost</dt>
                <dd></dd>
             </template>
             <dt>taxaccnos</dt>
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
    props: ["multi", "type"],
    data() {
       return {
       };
    }
};
</script>
