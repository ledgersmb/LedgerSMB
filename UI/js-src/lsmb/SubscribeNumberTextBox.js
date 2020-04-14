/** @format */

define([
   "dojo/_base/declare",
   "dojo/topic",
   "dijit/form/NumberTextBox"
], function (declare, topic, NumberTextBox) {
   return declare("lsmb/SubscribeNumberTextBox", NumberTextBox, {
      topic: "",
      update: function (targetValue) {
         this.set("value", targetValue);
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
