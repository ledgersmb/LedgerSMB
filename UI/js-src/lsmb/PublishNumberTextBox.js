/** @format */

define([
   "dojo/_base/declare",
   "dojo/on",
   "dojo/topic",
   "dijit/form/NumberTextBox",
], function (declare, on, topic, NumberTextBox) {
   return declare("lsmb/PublishNumberTextBox", NumberTextBox, {
      topic: "",
      publish: function (targetValue) {
         topic.publish(this.topic, targetValue);
      },
      postCreate: function () {
         var self = this;
         this.own(
            on(this, "change", function (targetValue) {
               self.publish(targetValue);
            })
         );
      },
   });
});
