define("lsmb/Timecard-weekly",
       ["dojo/_base/declare",
        "dojo/topic",
        "dojo/dom",
        "dijit/registry",
        "dojo/_base/array",
        "lsmb/Form"],
       function(declare, topic, dom, registry, array, Form) {
           return declare("lsmb/Timecard-weekly", Form, {
               update: function(targetValue) {
                   this.set("checked", true);
                   this._display(( targetValue == 'by_time' ||
                                   targetValue == 'by_overhead' ) ? ''
                                                                  : 'none');
               },
               _display: function(s) {
                   var widget = dom.byId('in-time');
                   if ( widget) widget.style = 'display:'+s;
               },
               _disableWidgets: function(state) {
                   var widgets = registry.findWidgets(dom.byId('timecard-weekly'));
                   if (widgets) array.forEach(widgets, function(widget, index) {
                       widget.set('disabled', state);
                   });
               },
               startup: function() {
                   var self = this;
                   this.inherited(arguments);

                   topic.subscribe(this.topic,
                        function(targetValue) {
                            self.update(targetValue);
                        });

//                   var in_id = dom.byId('id').value;
//                   var in_edit = Number(dom.byId('in-edit').value);
//                   self._disableWidgets(in_id != '' && in_edit===0);
               }
           });
       });