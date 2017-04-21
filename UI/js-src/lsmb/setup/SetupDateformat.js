define([
    "dojo/_base/declare",
    "dojo/topic",
    "dijit",
    "lsmb/DateTextBox"
    ], function(
      declare,
        topic,
        dijit,
     DateTextBox
      ){
        return declare("lsmb/setup/SetupDateformat", [DateTextBox], {
            store:  null,
            country_dateformat: 0,
            searchAttr: "date_format",
            labelAttr: "name",
            postCreate: function() {
                var self = this;
                store = this.store;
                country_dateformat = this.country_dateformat;
                this.inherited(arguments);
                if (this.topic) {
                    this.own(
                        topic.subscribe(
                            this.topic,
                            function(selected) {
                                var dfmt;
                                if (country_dateformat) {
                                var item = store.get(selected);
                                    dfmt = item['date_format'];
                                }
                                if ( !dfmt ) {
                                    dfmt = 'yyyy-MM-DD';
                                }
                                var constraints = self.get('constraints');
                                constraints.datePattern = dfmt;
                                self.set('constraints', constraints);
                                self.set('placeholder',dfmt);
                            }));
                }
            }, // startup
        });
    });
