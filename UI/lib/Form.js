define([
    'dijit/form/Form',
    'dojo/_base/declare',
    'dojo/_base/event',
    'dojo/on'
    ],
       function(Form, declare, event, on) {
           return declare('lsmb/lib/Form',
                          [Form],
              {
                  postCreate: function() {
                      var self = this;
                      this.inherited(arguments);
                      on(this.domNode, 'submit',
                             function(e){
                                 var rv = self.validate();
                                 if (!rv) {
                                     event.stop(e);
                                 }
                                 return rv;
                             });
                  }
              });
       }
    );
