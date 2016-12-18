define("lsmb/Timecard",
       ["dijit/layout/ContentPane",
        "dojo/_base/declare",
        "dojo/topic",
        "dojo/date",
        "dojo/date/locale",
        "dojo/dom-attr",
        "dojo/dom",
        "dijit/registry",
        "dojo/_base/array",
        "dijit/form/RadioButton",
        "dojo/domReady!"],
       function(ContentPane, declare, topic, date, locale, domAttr, dom, registry, array, RadioButton) {
           return declare("lsmb/Timecard", ContentPane, {
               update: function(targetValue) {
                   this.set("checked", true);
                   this._display( targetValue == 'by_time'
                               || targetValue == 'by_overhead'
                                               ? ''
                                               : 'none');
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
               postCreate: function() {
                   var self = this;
                   this.inherited(arguments);
                   topic.subscribe(this.topic,
                        function(targetValue) {
                            self.update(targetValue);
                        });
                   var in_id = dom.byId('id').value;
                   var in_edit = Number(dom.byId('in-edit').value);
                   self._disableWidgets(in_id != '' && in_edit===0);
                   var date = new Date();
                   var transdate = dom.byId('in-transdate');
                   if (transdate && transdate.innerText == '') {
                       var ymd = x = dojo.date.locale.format(date, {datePattern: date.placeholder, selector: "date"});;
                       domAttr.set(transdate,'value',ymd);
                   }
                   var in_hour = dom.byId('in-hour');
                   if (in_hour && in_hour.innerText == '') {
                       var h = '00'+date.getHours().toString();
                       domAttr.set(in_hour,'value',h.slice(-2));
                   }
                   var in_min = dom.byId('in-min');
                   if (in_min && in_min.innerText == '') {
                       var m = '00'+date.getMinutes().toString();
                       domAttr.set(in_min,'value',m.slice(-2));
                   }
               }
           });
       });