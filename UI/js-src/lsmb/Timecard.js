define("lsmb/Timecard",
       ["dojo/_base/declare",
        "dojo/topic",
        "dojo/dom",
        "dojo/dom-attr",
        "dijit/registry",
        "dojo/_base/array",
        "dojo/io-query",
        "dojo/request/xhr",
        "dojo/number",
        "dojo/_base/kernel",
        "dojo/currency",
        "lsmb/Form"],
       function(declare, topic, dom, domattr, registry, array, query, xhr, number, kernel, currency, Form) {
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
                   } else if (topic == 'part' || topic == 'fxrate') {
                       this._refresh_screen();
                   } else if (topic == 'unitprice') {
                   } else if (topic == 'qty') {
                       if (dom.byId('qty').value != targetValue) {
                           domattr.set('in-hour','value','');
                           domattr.set('in-min','value','');
                           domattr.set('out-hour','value','');
                           domattr.set('out-min','value','');
                           domattr.set('total','value','');
                       }
                   } else if (topic == 'curr' || topis == 'date') {
                       this.defaultcurr = dom.byId('defaultcurr').value;
                       this.curr = targetValue;
                       this.transdate = dom.byId('transdate').value;
                       if (this.curr != this.defaultcurr) {
                           this._getFXRate();
                       } else {
                           domattr.set('fxrate','value','');
                       }
                   }
                   var qty = this._number_parse(dom.byId('qty').value);
                   var unitprice = this._number_parse(dom.byId('unitprice').value);
                   var fxrate = this._number_parse(dom.byId('fxrate').value);
                   var sellprice = this._currency_format(qty * unitprice);
                   var fxsellprice = this._currency_format(qty * unitprice * fxrate);
                   dom.byId('sellprice').innerHTML = sellprice;
                   dom.byId('fxsellprice').innerHTML = fxsellprice;
               },
               _number_parse: function (n) {
                   return number.parse(n, { locale: kernel.locale })
               },
               _currency_parse: function (n) {
                   return currency.parse(n, { currency: this.defaultcurr })
               },
               _currency_format(n) {
                  return currency.format(n, { currency: this.defaultcurr});
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
               },
               _disableWidgets: function(state) {
                   var widgets = registry.findWidgets(dom.byId('tableTimecard'));
                   if (widgets) array.forEach(widgets, function(widget, index) {
                       widget.set('disabled', state);
                   });
               },
               _getFXRate: function() {
                   var self = this;
                   var get = query.queryToObject(decodeURIComponent(dojo.doc.location.search.slice(1)));
                   var fxrate = dom.byId('fxrate');
                   xhr("/getrate.pl?action=getrate"
                                   + "&date=" + this.transdate
                                   + "&curr=" + this.curr
                                   + "&company=" + get.company
                   ).then(function(data){
                       data = self._number_parse(data);
                       domattr.set('fxrate','value',data);
                       var sellprice = self._currency_parse(dom.byId('sellprice').innerHTML);
                       dom.byId('fxsellprice').innerHTML = self._currency_format(sellprice * data);
                   }, function(error){
                       domattr.set('fxrate','value',"Error: " + error.message);
                       dom.byId('fxsellprice').innerHTML = 'N/A';
                   });
               },
               startup: function() {
                   var self = this;
                   this.inherited(arguments);

                   if (this.topic) {
                       var topics = ['type','clocked','qty','curr','unitprice','fxrate','part','date'];
                       topics.forEach(function(_topic) {
                           topic.subscribe(self.topic+_topic,
                                function(targetValue) {
                                    self.update(targetValue,_topic);
                                }
                           )
                       });
                       topic.subscribe(self.topic+"part-select/day",
                            function(targetValue) {
                                self.update(targetValue,'part');
                            }
                       )
                   }
                   var in_id = dom.byId('id').value;
                   var in_edit = Number(dom.byId('in-edit').value);

                   self.transdate = dom.byId('transdate').value;
                   self.defaultcurr = dom.byId('curr').value;
                   self._disableWidgets(in_id != '' && in_edit===0);
               }
           });
       });
