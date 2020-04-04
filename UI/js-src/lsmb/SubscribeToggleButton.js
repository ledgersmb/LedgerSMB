/** @format */

define([
   "dojo/_base/declare",
   "dojo/topic",
   "dijit/form/ToggleButton",
], function (declare, topic, ToggleButton) {
   return declare("lsmb/SubscribeToggleButton", [ToggleButton], {
      update: function (targetValue) {
         this.set("checked", targetValue);
      },
      postCreate: function () {
         var self = this;
         this.inherited(arguments);

         this.own(
            topic.subscribe(self.topic, function (targetValue) {
               self.update(targetValue);
            })
         );
      }
   });
});
