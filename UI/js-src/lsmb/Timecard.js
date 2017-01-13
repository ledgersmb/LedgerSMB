define("lsmb/Timecard",
       ["dojo/_base/declare",
        "dojo/topic",
        "dojo/dom",
        "dojo/dom-attr",
        "dijit/registry",
        "dojo/_base/array",
        "dojo/number",
        "dojo/io-query",
        "dojo/request/xhr",
        "lsmb/Form"],
       function(declare, topic, dom, domattr, registry, array, number, query, xhr, Form) {
           return declare("lsmb/Timecard", Form, {
               topic: null,
               defaultcurr: "",
               curr: "",
               transdate: "",
               decimal_places: 7,
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
                       var v = ( inh && inm && outh && outm && _out > _in )
                             ? this._number_format((_out-_in)/60.0, this.decimal_places) : '';
                       // Should we prevent event bubbling?
                       domattr.set('qty','value',v);
                       dom.byId('total').innerHTML = this._number_format(v,this.decimal_places);
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
                   } else if (topic == 'curr' || topic == 'date') {
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
                   domattr.set('sellprice','value',sellprice);
                   if (this.curr == this.defaultcurr) {
                       domattr.set('sellprice','value','');
                   } else {
                       var fxsellprice = this._currency_format(
                                    qty * unitprice * fxrate,
                                    this.decimal_places);
                       domattr.set('fxsellprice','value',fxsellprice);
                   }
               },
               _number_parse: function (n) {
                   return parseFloat(n)
               },
               _currency_parse: function (n) {
                   return parseFloat(n)
               },
               _number_format(n,p) {
                  return number.format(n, {
                      places: p,
                      locale: 'us-us'
                    })
               },
               _currency_format(n,p) {
//                  return n
                  return number.format(n, {
                      places: p,
                      locale: 'us-us'
                    })
               },
               _refresh_screen: function () {
                   // Nothing currently
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
