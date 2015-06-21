define(['dojo/_base/declare',
        'dojo/on',
        'dojo/topic',
        'dijit/form/Select'],
       function(declare, on, topic, Select) {
           return declare('SubscribeSelect', [Select], {
               topic: "",
               topicMap: {},
               update: function(targetValue) {
                   var newValue = this.topicMap[targetValue];
                   if (newValue) {
                       this.set('value', newValue);
                   }
               },
               postCreate: function() {
                   var self = this;
                   this.inherited(arguments);

                   this.own(
                       topic.subscribe(self.topic,function(targetValue) {
                           self.update(targetValue);
                       })
                   );
               },
           });
       });
