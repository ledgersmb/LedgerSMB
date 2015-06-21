define(['dojo/_base/declare',
        'dojo/on',
        'dojo/topic',
        'dijit/form/Select'],
       function(declare, on, topic, Select) {
           return declare('PublishSelect', [Select], {
               topic: "",
               publish: function(targetValue) {
                   topic.publish(this.topic, targetValue);
               },
               postCreate: function() {
                   var self = this;
                   this.inherited(arguments);
                   this.own(
                       on(this, 'change',
                          function(targetValue) {
                              self.publish(targetValue);
                          })
                   );
               },
           });
       });
