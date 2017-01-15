define("lsmb/Timecard",
       ["dojo/_base/declare",
        "dojo/topic",
        "dojo/dom",
        "dijit/registry",
        "dojo/_base/array",
        "dojo/number",
        "dojo/Evented",
        "lsmb/Form"],
       function(declare, topic, dom, registry, array, number, evented, Form) {
           return declare("lsmb/Timecard", [Form, evented], {
               topic: null,
               defaultcurr: "",
               curr: "",
               transdate: "",
               qty: undefined,
               total: undefined,
               non_billable: undefined,
               fxrate: undefined,
               unitprice: undefined,
               sellprice: undefined,
               fxsellprice: undefined,
               language: '',
               jctype: undefined,
               decimal_places: 2,
               // We should stop event bubbling while updating - YL
               _update: function(targetValue,topic) {
                   if (topic == 'type'){
                       this.jctype = targetValue;
                       this._display(( targetValue == 'by_time' ||
                                       targetValue == 'by_overhead' ) ? ''
                                                                      : 'none');
                       this._refresh_screen();
                   } else if (topic == 'clocked') {
                       var inh = registry.byId('in-hour').get('value');
                       var inm = registry.byId('in-min').get('value');
                       var outh = registry.byId('out-hour').get('value');
                       var outm = registry.byId('out-min').get('value');
                       var _in = parseInt(inh) * 60.0 + parseInt(inm);
                       var _out = parseInt(outh) * 60.0 + parseInt(outm);
                       var total = ( inh >= 0 && inm >= 0 && outh >= 0 && outm >= 0 && _out > _in )
                             ? (_out-_in)/60.0 : undefined;
                       if ( total != this.total ) {
                           this.total = total;
                           registry.byId('total').set('value',this._number_format(this.total));
                           if ( this.total ) {
                               this.qty = this.total;
                               // We must prevent event bubbling - YL
                               //???.preventDefault();
                               registry.byId('qty').set('value',this._number_format(this.qty));
                           }
                       }
                   } else if (topic == 'part-select/day') {
                       this.unitprice = targetValue.sellprice;
                       registry.byId('unitprice').format(this.unitprice,{ currency: this.curr});
                       this._refresh_screen();
                   } else if (topic == 'fxrate') {
                       this.fxrate = targetValue;
                   } else if (topic == 'unitprice') {
                       this.unitprice = targetValue;
                   } else if (topic == 'qty') {
                       if (this.total) {
                           registry.byId('in-hour').set('value','');
                           registry.byId('in-min').set('value','');
                           registry.byId('out-hour').set('value','');
                           registry.byId('out-min').set('value','');
                           registry.byId('total').set('value','');
                           this.total = undefined;
                       }
                       this.qty = targetValue;
                   } else if (topic == 'date') {
                       this.transdate = registry.byId('transdate').get('value');
                   } else if (topic == 'curr') {
                       this.curr = targetValue;
                       var _fx = registry.byId('fxrate');
                       if (this.curr == this.defaultcurr) {
                           _fx.set('value','');
                           _fx.setAttribute('readOnly', true);
                           this.fxrate = 0;
                           registry.byId('sellprice').constraints.currency = this.curr;
                       } else {
                           _fx.setAttribute('readOnly', false);
                           registry.byId('sellprice').constraints.currency = this.curr;
                       }
                   }
                   this.sellprice = this.qty * this.unitprice;
                   var _sp = registry.byId('sellprice');
                   _sp.set('value',_sp.format(this.sellprice,{ currency: this.curr}));
                   _sp = registry.byId('fxsellprice');
                   if (this.curr == this.defaultcurr) {
                       _sp.set('value','');
                   } else {
                       this.fxsellprice = this.qty * this.unitprice * this.fxrate;
                       _sp.set('value',_sp.format(this.fxsellprice,{ currency: this.defaultcurr}));
                   }
                   this.non_billable = this._number_parse(registry.byId('non-billable').get('value'));
                   this._validate_field(targetValue);
               },
               _number_parse(n) {
                  return number.parse(n, {
                      places: this.decimal_places,
                      locale: this.language
                    })
               },
               _number_format(n) {
                  return n;
                  return number.format(n, {
                      places: this.decimal_places,
                      locale: this.language
                    })
               },
               _currency_parse(n) {
                  return number.parse(n, {
                      places: this.decimal_places,
                      locale: this.language
                    })
               },
               _currency_format(n) {
                  return n;
                  return number.format(n, {
                      places: this.decimal_places,
                      locale: this.language
                    })
               },
               _refresh_screen: function () {
                   // Nothing currently
               },
               _display: function(s) {
                   var widget = dom.byId('clock-time');
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
               validate: function() {
                   console.log('Validated?');
               },
               _validate_field: function(targetValue) {
                   var pn = registry.byId('partnumber').get('value');
                   var pd = registry.byId('description').get('value');
                   var enabled = this.jctype != ""
                              && (pn || pd)
                              && this.qty
                              && this.sellprice
                              && (this.defaultcurr == this.curr || this.fxsellprice);
                   dijit.byId('action_save').setAttribute('disabled', !enabled);
               },
               isValid: function () {
                   return false;
               },
               startup: function() {
                   var self = this;
                   this.inherited(arguments);

                   var topics = ['type','clocked','qty','curr','unitprice','fxrate','unit','date','part-select/day'];
                   topics.forEach(function(_topic) {
                       topic.subscribe(self.topic+_topic,
                            function(targetValue) {
                                self._update(targetValue,_topic);
                            }
                       );
                   });
                   self.transdate = dom.byId('transdate').value;
                   self.curr = registry.byId('curr').get('value');
                   self.defaultcurr = dom.byId('defaultcurr').value;
                   self.language = dom.byId('language1').value;
                   self.decimal_places = dom.byId('decimal-places').value;

                   var in_id = dom.byId('id').value;
                   var in_edit = Number(dom.byId('in-edit').value);
                   self._disableWidgets(in_id != '' && in_edit===0);
               }
           });
       });
