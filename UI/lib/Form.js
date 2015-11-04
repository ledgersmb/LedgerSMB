define([
    'dijit/form/Form',
    'dojo/_base/declare',
    'dojo/_base/event',
    'dojo/io-query',
    'dojo/on',
    'dojo/dom-form'
    ],
       function(Form, declare, event, ioquery, on, domForm) {
           return declare('lsmb/lib/Form',
                          [Form],
              {
                  postCreate: function() {
                      var self = this;
                      this.inherited(arguments);
                      on(this.domNode, 'submit',
                             function(e){
                                 var rv = self.validate();
                                 console.log('Validation returned', rv);
                                 console.log(self.domNode.getAttribute('id'));
                                 console.log(self.domNode.id, domForm.toObject(self.domNode.getAttribute('id')));
                                 console.log(ioquery.objectToQuery(domForm.toObject(self.domNode.getAttribute('id'))));
                                 if (!rv) {
                                     event.stop(e);
                                 }
                                 return rv;
                             });
                  }
              });
       }
    );
