define("lsmb/Timecard",
       ["dojo/_base/declare",
        "dojo/topic",
        "dojo/date",
        "dojo/date/locale",
        "dojo/dom-attr",
        "dojo/dom",
        "dijit/registry",
        "dojo/query",
        "dojo/_base/array",
        "lsmb/Form",
        "dijit/_Container"],
       function(declare, topic, date, locale, domAttr, dom, registry, query, array, Form, _Container) {
           return declare("lsmb/Timecard", [Form, _Container], {
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
                   var widgets = registry.findWidgets(dom.byId('tableTimecard'));
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

                   var in_id = dom.byId('id').value;
                   var in_edit = Number(dom.byId('in-edit').value);
                   self._disableWidgets(in_id != '' && in_edit===0);

                   var date = new Date();

                   var transdate = dom.byId('in-transdate');
                   if (transdate && transdate.innerText == '') {
                       var ymd = x = dojo.date.locale.format(date, {datePattern: date.placeholder, selector: "date"});;
                       domAttr.set(transdate,'value',ymd);
                   }
               }
           });
       });