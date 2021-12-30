<template>
   <div>
     <table class="dynatable report">
       <thead>
          <tr>
             <th v-for="column in columns" :class="column.key">{{ column.head }}</th>
             <th></th>
          </tr>
       </thead>
       <tbody>
         <wh-row v-for="warehouse in warehouses"
                 :columns="columns"
                 :storeData="warehouse"
                 :key="warehouse.id" />
       </tbody>
       <tfoot>
          <tr>
              <td>
                  <input style="background-color:transparent"
                         type="text"
                         :value="n.description"
                         @input="updateDescription" />
             </td>
             <td>
                <button @click="addNew">Add</button>
             </td>
          </tr>
       </tfoot>
     </table>
   </div>
</template>


<script>

import { useWarehousesStore } from "@/store/warehouses";
import { mapState } from "pinia";
import rowComponent from "./WarehouseRow.vue";

const COLUMNS = [
   { key: "description", type: "text",     head: "Description" },
];

export default {
   components: {
      "wh-row": rowComponent
   },
   data() {
      return {
         columns: COLUMNS,
         n: {
            description: ""
         }
      }
   },
   computed: {
      ...mapState(useWarehousesStore, ["warehouses"])
   },
   methods: {
    addNew() {
         let warehouses = useWarehousesStore();
         warehouses.add(this.n.description);
         this.n.description = "";
      },
      updateDescription(event) {
         this.n.description = event.target.value;
      },
      reset() {
      }
   }
};

</script>
