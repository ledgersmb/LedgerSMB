/** @format */

define([
   "dojo/_base/declare",
   "dojo/on",
   "dojo/topic",
   "dijit/form/ToggleButton",
], function (declare, on, topic, ToggleButton) {
   return declare("lsmb/PublishToggleButton", [ToggleButton], {
      publish: function (targetValue) {
         topic.publish(this.topic, targetValue);
         this.set(
            "iconClass",
            targetValue
               ? "dijitTreeIcon dijitFolderOpened"
               : "dijitTreeIcon dijitFolderClosed"
         );
      },
      postCreate: function () {
         var self = this;
         this.inherited(arguments);
         this.own(
            on(this, "change", function (targetValue) {
               self.publish(targetValue);
            })
         );
         self.publish(self.checked);
      }
   });
});
