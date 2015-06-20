define(['dojo/_base/declare',
        'dojo/on',
        'dojo/topic',
        'dijit/form/CheckBox'],
       function(declare, on, topic, CheckBox) {
           return declare('PublishCheckbox', [CheckBox], {
               topic: "",
               publish: function(targetValue) {
                   topic.publish(this.topic, targetValue);
               },
               postCreate: function() {
                   var self = this;
                   this.own(
                       on(this, 'change',
                          function(targetValue) {
                              self.publish(targetValue);
                          })
                   );
               },
           });
       });
