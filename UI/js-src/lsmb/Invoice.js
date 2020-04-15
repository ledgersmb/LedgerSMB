/** @format */

define([
   "dojo/_base/declare",
   "dijit/registry",
   "dojo/on",
   "lsmb/Form",
   "dijit/_Container",
], function (declare, registry, on, Form, _Container) {
   return declare("lsmb/Invoice", [Form, _Container], {
      _update: function () {
         this.clickedAction = "update";
         this.submit();
      }, // update
      startup: function () {
         var self = this;
         this.inherited(arguments);
         this.own(
            on(registry.byId("invoice-lines"), "changed", function () {
               self._update();
            })
         );
      }, // startup
   });
});
