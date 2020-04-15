/** @format */

define([
   "dojo/store/JsonRest",
   "dojo/store/Observable",
   "dojo/store/Memory",
   "dojo/store/Cache",
   "dojo/request",
   "dojo/_base/array",
   "dojo/_base/declare",
   "dojo/Evented",
   "dojo/request",
], function (
   JsonRest,
   Observable,
   Memory,
   Cache,
   request,
   array,
   declare,
   Evented,
   xhr
) {
   var accountsRest = declare("lsmb/accounts/AccountRestStore", [JsonRest], {
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
   var store = new Cache(
      new accountsRest({
         idProperty: "accno",
         target: "/erp/api/v0/accounts/",
      }),
      new Memory()
   );
   return store;
});
