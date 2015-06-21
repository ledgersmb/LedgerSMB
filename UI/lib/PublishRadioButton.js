define(['dojo/_base/declare',
        'dojo/on',
        'dojo/topic',
        'dijit/form/RadioButton'],
       function(declare, on, topic, RadioButton) {
           return declare('PublishRadioButton', [RadioButton], {
               topic: "",
               publish: function() {
                   topic.publish(this.topic, this.value);
               },
               postCreate: function() {
                   var self = this;
                   this.own(
                       on(this.domNode, 'change',
                          function() {
                              self.publish();
                          })
                   );
               },
           });
       });
