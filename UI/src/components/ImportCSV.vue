<template>
  <div id="{{ type }}">
    <div class="listtop">{{ title }}</div>
    <div class="info">{{ info }}</div>
    <form>
      <input type="hidden" name="type" value="{{ type }}">
         <div v-if="multi"
              class="listtop">Batch Information')</div>
      <div class="two-column-grid" style="width: fit-content">
        <lsmb-text class="reference"
                 name="reference"
                 title="Reference"
                 value=""
                 size="15" ></lsmb-text>
        <lsmb-text class="description"
                 name="description"
                 title="Description"
                 value="" ></lsmb-text>
        <lsmb-date title="Transaction Date"
                 name="transdate"
                 size="12" ></lsmb-date>
        <lsmb-file name="import_file"
               label="From File"
               accept = ".csv" ></lsmb-file>

      </div>
      <div class="inputrow" id="buttonrow">
        <input type="hidden" name="trans_type" />
        <button type="submit" class="submit"
                name="action" value="run_import">{{ "Save" }}</button>
      </div>
    </form>
  </div>
</template>

<script>

function markDone() {
}

export default {
    props: [ "multi", "info", "title", "type" ],
    mounted() {
        markDone();
    },
    updated() {
        markDone();
    }
};
</script>
