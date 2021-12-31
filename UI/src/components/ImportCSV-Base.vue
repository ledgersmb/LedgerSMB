<template>
  <div :id="type">
    <div class="listtop"><slot name="title" /></div>
    <div class="info"><slot name="info" /></div>
    <form name="csvupload">
      <input type="hidden" name="type" :value="type">
      <div v-if="multi"
           class="listheading">Batch Information</div>
      <div class="two-column-grid" style="width:fit-content;grid-gap:4px">
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
        <lsmb-file name="import_file"
               label="From File"
               accept=".csv"
               required
               @change="status=null" />

      </div>
      <div class="inputrow" id="buttonrow">
        <input type="hidden" name="trans_type" />
        <lsmb-button class="submit"
                name="action" @click="upload">{{ "Save" }}</lsmb-button>
      </div>
      <div v-show="status!==null" :class='status ? "success" : "failure"'>
        {{ message }}
      </div>
      <slot />
    </form>
  </div>
</template>

<style>

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
    props: [ "multi", "type" ],
};
</script>
