/** @format */

define([
   "dijit/form/FilteringSelect",
   "dojo/_base/declare",
   "dojo/keys",
], function (FilteringSelect, declare, keys) {
   return declare("lsmb/FilteringSelect", [FilteringSelect], {
      onKey: function (e) {
         var d = this.dropDown;
         if (d && e.keyCode === keys.TAB) {
            this.onChange(d.getHighlightedOption());
         }
         return this.inherited(arguments);
      }
   });
});
