<template>
   <import-csv :type="type">
     <template v-slot:title>Import GL transaction</template>
     <template v-slot:info>The uploaded file contains the lines in the transaction;
          the header data is entered into the fields below.</template>
     <template v-slot:default>
        The first row of the file contains the field names; all following rows contain
        lines to be uploaded. The following fields are expected (in this order):
        <dl>
          <dt>accno</dt>
          <dd>GL acount code (accno) for the debit or credit to be posted</dd>

          <dt>debit</dt>
          <dd>The debit amount to be posted on the line, in the functional (or "native")
              currency; note that a single line can be <em>either</em> debit or credit</dd>

          <dt>credit</dt>
          <dd>The credit amount to be posted on the line</dd>

          <dt>curr</dt>
          <dd>The currency to be used for the transaction; if the transaction does not
              concern foreign currencies, fill out the default currency of the company</dd>

          <dt>debit_fx</dt>
          <dd>The foreign currency (transaction currency) debit amount in case of a foreign
              currency transaction; in case the default currency applies, fill with the same
              amount as the <code>debit</code> field</dd>

          <dt>credit_fx</dt>
          <dd>The foreign currency (transaction currency) credit amount in case of a foreign
              currency transaction; in case the default currency applies, fill with the same
              amount as the credit field</dd>

          <dt>source</dt>
          <dd>The identifier of the transaction(line) in an external system; used for e.g.
              bank reconciliation</dd>

          <dt>memo</dt>
          <dd>A note field for the specific transaction line</dd>

        </dl>
     </template>
   </import-csv>
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
          type: 'gl'
       };
    }
};
</script>
