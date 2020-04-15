/** @format */

define([
   "dojo/store/JsonRest",
   "dojo/store/Observable",
   "dojo/request",
   "dojo/_base/array",
   "dojo/_base/declare",
   "dojo/Evented",
   "dojo/request",
   "dojo/io-query",
], function (JsonRest, Observable, request, array, declare, Evented, xhr, io) {
   console.log("creating store");
   var partsRest = declare("lsmb/parts/PartRestStore", [JsonRest], {
      get: function (id) {
         var self = this;
         var r = request.get(this.target, {
            handleAs: "json",
            headers: this.headers,
         });
         var rv = r.then(function (data) {
            var theOne;
            array.forEach(data, function (item) {
               if (id == item[self.idProperty]) {
                  theOne = item;
               }
            });
            return theOne;
         });
         return rv;
      },
      query: function (query, options) {
         if (query && typeof query == "object") {
            query = "?" + io.objectToQuery(query);
         }
         if (options && options.type) {
            query = "?type=" + options.type + "&" + query;
         }
         return this.inherited(arguments, [query, options]);
      },
   });
   var store = new Observable(
      new partsRest({
         idProperty: "partnumber",
         target: "erp/api/v0/goods/",
      })
   );
   console.log("done creating store");
   return store;
});
