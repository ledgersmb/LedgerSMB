/** @format */

/* eslint no-template-curly-in-string:0 */

define([
   "lsmb/FilteringSelect",
   "dojo/_base/declare",
   "dojo/aspect",
   "dojo/topic",
   "lsmb/parts/PartRestStore"
], function (Select, declare, aspect, topic, store) {
   var mySelect = new declare("lsmb/parts/PartSelector", [Select], {
      store: store,
      queryExpr: "*${0}*",
      style: "width: 15ex",
      highlightMatch: "all",
      searchAttr: "partnumber",
      labelAttr: "label",
      autoComplete: false,
      initialValue: null,
      channel: null,
      constructor: function () {
         this.inherited(arguments);
         this.initialValue = arguments[0].value;
      },
      startup: function () {
         var self = this;
         this.inherited(arguments);
         if (this.channel) {
            this.own(
               topic.subscribe(this.channel, function (selected) {
                  self.set("value", selected[self.searchAttr]);
               })
            );
            // eslint-disable-next-line no-unused-vars
            this.on("change", function (newValue) {
               topic.publish(self.channel, self.item);
            });
         }
      }
   });

   aspect.around(mySelect, "_announceOption", function (orig) {
      return function (node) {
         var savedSearchAttr = this.searchAttr;
         this.searchAttr = this.labelAttr;
         var r = orig.call(this, node);
         this.searchAttr = savedSearchAttr;
         return r;
      };
   });
   return mySelect;
});
