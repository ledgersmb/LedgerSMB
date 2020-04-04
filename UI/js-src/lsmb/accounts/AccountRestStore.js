/** @format */

define([
   "dojo/store/JsonRest",
   "dojo/store/Memory",
   "dojo/store/Cache",
   "dojo/request",
   "dojo/_base/array",
   "dojo/_base/declare",
], function (jsonRest, memory, cache, request, array, declare) {
   var accountsRest = declare("lsmb/accounts/AccountRestStore", [jsonRest], {
      get: function (id) {
         var self = this;
         var r = request.get(this.target, {
            handleAs: "json",
            headers: this.headers,
         });
         var rv = r.then(function (data) {
            var theOne;
            array.forEach(data, function (item) {
               if (id === item[self.idProperty]) {
                  theOne = item;
               }
            });
            return theOne;
         });
         return rv;
      },
   });
   var store = new cache(
      new accountsRest({
         idProperty: "accno",
         target: "/erp/api/v0/accounts/",
      }),
      new memory()
   );
   return store;
});
