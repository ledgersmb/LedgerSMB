/** @format */

define(["dojo/_base/declare", "dojo/topic", "dijit/form/CheckBox"], function (
    declare,
    topic,
    CheckBox
) {
    return declare("lsmb/SubscribeCheckBox", [CheckBox], {
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
