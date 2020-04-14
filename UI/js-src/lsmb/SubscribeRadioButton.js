/** @format */

define([
   "dojo/_base/declare",
   "dojo/topic",
   "dijit/form/RadioButton"
], function (declare, topic, RadioButton) {
   return declare("lsmb/SubscribeRadioButton", [RadioButton], {
      topic: "",
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
