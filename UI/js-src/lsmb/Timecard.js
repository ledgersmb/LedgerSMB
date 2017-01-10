define("lsmb/Timecard",
       ["dojo/_base/declare",
        "dojo/topic",
        "dojo/dom",
        "dojo/dom-attr",
        "dijit/registry",
        "dojo/_base/array",
        "dojo/io-query",
        "dojo/request/xhr",
        "lsmb/Form"],
       function(declare, topic, dom, domattr, registry, array, query, xhr, Form) {
           return declare("lsmb/Timecard", Form, {
               topic: null,
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
                       this._refresh_screen();
                   } else if (topic == 'clocked') {
                       var inh = dom.byId('in-hour').value;
                       var inm = dom.byId('in-min').value;
                       var outh = dom.byId('out-hour').value;
                       var outm = dom.byId('out-min').value;
                       var _in = parseInt(inh) * 60.0 + parseInt(inm);
                       var _out = parseInt(outh) * 60.0 + parseInt(outm);
                       var v = ( inh && inm && outh && outm && _out > _in ) ? (_out-_in)/60.0 : '';
                       domattr.set('total','value',v);
                       // Should we prevent event bubbling?
                       domattr.set('qty','value',v);
                   } else if (topic == 'part-select/day' || topic == 'fxrate') {
                       this._refresh_screen();
                   } else if (topic == 'unitprice') {
                       // Nothing special to do
                   } else if (topic == 'qty') {
                       if (dom.byId('qty').value != targetValue) {
                           domattr.set('in-hour','value','');
                           domattr.set('in-min','value','');
                           domattr.set('out-hour','value','');
                           domattr.set('out-min','value','');
                           domattr.set('total','value','');
                       }
                   } else if (topic == 'curr' || topis == 'date') {
                       this.curr = targetValue;
                       this.transdate = dom.byId('transdate').value;
                       if (this.curr == this.defaultcurr) {
                           domattr.set('fxrate','value','');
                       }
                   }
                   var qty = this._number_parse(dom.byId('qty').value);
                   var unitprice = this._number_parse(dom.byId('unitprice').value);
                   var fxrate = this._number_parse(dom.byId('fxrate').value);
                   var sellprice = this._currency_format(qty * unitprice);
                   dom.byId('sellprice').innerHTML = sellprice;
                   if (this.curr == this.defaultcurr) {
                       dom.byId('fxsellprice').innerHTML = '';
                   } else {
                       var fxsellprice = this._currency_format(qty * unitprice * fxrate);
                       dom.byId('fxsellprice').innerHTML = fxsellprice;
                   }
               },
               _number_parse: function (n) {
                   return parseFloat(n)
               },
               _currency_parse: function (n) {
                   return parseFloat(n)
               },
               _currency_format(n) {
                  return n
               },
               _refresh_screen: function () {
                   if ( this.domNode ) {
                       this.clickedAction = "refresh";
                       this.submit();
                   }
               },
               _display: function(s) {
                   var widget = dom.byId('in-time');
                   if ( widget) widget.style = 'display:'+s;
                   var widget = dom.byId('total');
                   if ( widget) widget.style = 'display:'+s;
               },
               _disableWidgets: function(state) {
                   var widgets = registry.findWidgets(dom.byId('tableTimecard'));
                   if (widgets) array.forEach(widgets, function(widget, index) {
                       widget.set('disabled', state);
                   });
               },
               startup: function() {
                   var self = this;
                   this.inherited(arguments);

                   var topics = ['type','clocked','qty','curr','unitprice','fxrate','unit','date','part-select/day'];
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
                   self.curr = dom.byId('curr').value;
                   self.defaultcurr = dom.byId('defaultcurr').value;
                   self._disableWidgets(in_id != '' && in_edit===0);
               }
           });
       });
