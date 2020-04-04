/** @format */

define(["dojo/_base/declare", "dojo/topic", "dijit/form/Select"], function (
   declare,
   topic,
   select
) {
   return declare("lsmb/SubscribeSelect", [select], {
               topic: "",
               topicMap: {},
      update: function (targetValue) {
         var newValue = this.topicMap[targetValue];
         if (newValue) {
            this.set("value", newValue);
         }
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
