/** @format */

define([
   "dojo/_base/declare",
   "dojo/on",
   "dojo/topic",
   "dijit/form/CheckBox",
], function (declare, on, topic, CheckBox) {
   return declare("lsmb/PublishCheckBox", [CheckBox], {
      topic: "",
      publish: function (targetValue) {
         topic.publish(this.topic, targetValue);
      },
      postCreate: function () {
         var self = this;
         this.inherited(arguments);
         this.own(
            on(this, "change", function (targetValue) {
               self.publish(targetValue);
            })
         );
      }
   });
});
