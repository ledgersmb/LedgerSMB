<template>
  <tr>
      <td v-for="column in columns">
          <input :type="column.type" :value="values[column.key]"
                 :name="column.key"
                 :readonly="!editing"
                 @input="update"
                 @click="checkClick"
                 style="background-color:transparent"
                    /></td>
    <td><button :disabled="editing" @click="edit">Edit</button>
        <button :disabled="!editing" @click="save">Save</button>
        <button :disabled="!editing" @click="cancel">Cancel</button>
    </td>
  </tr>
</template>


<script>

import { cloneDeep } from "lodash";
import { mapActions } from "pinia";

export default {
   props: ["columns", "storeData"],
   data() {
      return {
         editing: false,
         values: null
      }
   },
   methods: {
      ...mapActions("config/warehouses", {
            "saveWarehouse": "save"
      }),
      cancel() {
         this.reset();
         this.editing = false;
      },
      checkClick(event) {
         if (!this.editing) {
            event.preventDefault();
         }
      },
      edit() {
         this.editing = true;
      },
      reset() {
         this.values = cloneDeep(this.storeData);
      },
      save() {
         this.$parent.save(this.values);
         this.editing = false;
      },
      update(event) {
         this.values[event.target.name] = event.target.value;
      }
   },
   beforeMount() {
      this.reset();
   },
   watch: {
      storeData() {
         this.reset();
      }
   }
};


</script>
