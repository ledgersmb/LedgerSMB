define("lsmb/Timecard",
       ["dojo/_base/declare",
        "dojo/topic",
        "dojo/dom",
        "dojo/dom-attr",
        "dijit/registry",
        "dojo/_base/array",
        "dojo/request/xhr",
        "dojo/json",
        "lsmb/Form"],
       function(declare, topic, dom, domattr, registry, array, xhr, json, Form) {
           return declare("lsmb/Timecard", Form, {
               defaultcurr: "",
               curr: "",
               transdate: "",
               // We should stop event bubbling while updating - YL
               update: function(targetValue,topic) {
                   if (topic == 'type'){
                       this.set("checked", true);
                       this._display(( targetValue == 'by_time' ||
                                       targetValue == 'by_overhead' ) ? ''
                                                                      : 'none');
                       dijit.byId("action_save").setAttribute('disabled', false);
                       return;
                   } else if (topic == 'clocked') {
                       var inh = dom.byId('in-hour').value;
                       var inm = dom.byId('in-min').value;
                       var outh = dom.byId('out-hour').value;
                       var outm = dom.byId('out-min').value;
                       var _in = parseInt(inh) * 60.0 + parseInt(inm);
                       var _out = parseInt(outh) * 60.0 + parseInt(outm);
                       var v = ( inh && inm && outh && outm && _out > _in ) ? (_out-_in)/60.0 : '';
                       domattr.set('total','value',v);
                       domattr.set('qty','value',v);
                   } else if (topic == 'part') {
                       dom.byId("action_refresh").click();
                   } else if (topic == 'unitprice') {
                   } else if (topic == 'qty') {
                       if (dom.byId('qty').value != targetValue) {
                           domattr.set('in-hour','value','');
                           domattr.set('in-min','value','');
                           domattr.set('out-hour','value','');
                           domattr.set('out-min','value','');
                           domattr.set('total','value','');
                       }
                   } else if (topic == 'curr') {
                       this.defaultcurr = dom.byId('defaultcurr').value;
                       this.curr = targetValue;
                       this.transdate = dom.byId('transdate').value;
                       if (this.curr != this.defaultcurr) {
                           this._getFXRate();
                       } else {
                           domattr.set('fxrate','value','');
                       }
                   }
                   domattr.set('sellprice','value',dom.byId('qty').value
                                                 * dom.byId('unitprice').value);
                   domattr.set('fxsellprice','value',dom.byId('sellprice').value
                                                   * dom.byId('fxrate').value);
               },
               _update_save: function(targetValue) {
                   dijit.byId("action_save").setAttribute('disabled', false);
                   dom.byId("action_refresh").click();
               },
               _display: function(s) {
                   var widget = dom.byId('in-time');
                   if ( widget) widget.style = 'display:'+s;
               },
               _disableWidgets: function(state) {
                   var widgets = registry.findWidgets(dom.byId('tableTimecard'));
                   if (widgets) array.forEach(widgets, function(widget, index) {
                       widget.set('disabled', state);
                   });
               },
               _getFXRate: function() {
                   // Look up the node we'll stick the text under.
                   var fxrate = dom.byId('fxrate');
                   // We should provide a similar REST to cache results and fetch
                   // only if not available.
                   xhr.get("http://currencies.apps.grandtrunk.net/getrate/"
                                + this.transdate + "/" + this.curr
                                + "/" + this.defaultcurr, {
                                    headers: {
                                        'X-Requested-With': null,
                                        'Content-Type': 'text/plain'
                                    },
                                    preventCache: true
                   }).then(function(data){
                       var fx = json.stringify(data, true);
                       fxrate.innerHTML = fx;
                       domattr.set('fxsellprice','value',dom.byId('sellprice').value * fx);
                   }, function(error){
                       fxrate.innerHTML = "An unexpected error occurred: " + error.message;
                       domattr.set('fxsellprice','value','');
                   }, function(evt){
                       // Handle a progress event from the request if the
                       // browser supports XHR2
                   });
               },
               startup: function() {
                   var self = this;
                   this.inherited(arguments);

                   var topics = ['type','clocked','qty','curr','unitprice','part'];
                   topics.forEach(function(_topic) {
                       topic.subscribe(self.topic+_topic,
                            function(targetValue) {
                                self.update(targetValue,_topic);
                            }
                       );
                   });
                   var in_id = dom.byId('id').value;
                   var in_edit = Number(dom.byId('in-edit').value);

                   self.transdate = dom.byId('transdate').value;
                   self.defaultcurr = dom.byId('curr').value;
                   self._disableWidgets(in_id != '' && in_edit===0);
               }
           });
       });
