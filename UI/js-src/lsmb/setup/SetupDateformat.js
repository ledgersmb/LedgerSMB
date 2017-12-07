define([
    "dojo/_base/declare",
    "dojo/topic",
    "dojo/date/locale",
    "dojo/i18n",
    "lsmb/DateTextBox"
    ], function(
      declare,
        topic,
   datelocale,
         i18n,
     DateTextBox
      ){
        return declare("lsmb/setup/SetupDateformat", [DateTextBox], {
            dojo_dateformat: 0,
            _getFormat: function (options){
                    // summary:
                    //              Get the date Format as a String, using locale-specific settings.
                    //              Copied from dojo/date/locale
                    options = options || {};

                    var locale = i18n.normalizeLocale(options.locale),
                            formatLength = options.formatLength || 'short',
                            bundle = datelocale._getGregorianBundle(locale);

                            if(options.selector == "year"){
                            return bundle["dateFormatItem-yyyy"] || "yyyy";
                    }
                    var pattern;
                    if(options.selector != "date"){
                            pattern = options.timePattern || bundle["timeFormat-"+formatLength];
                    }
                    if(options.selector != "time"){
                            pattern = options.datePattern || bundle["dateFormat-"+formatLength];
                    }
                    return pattern;
            },
            postCreate: function() {
                var self = this;
                dojo_dateformat = this.dojo_dateformat;
                this.inherited(arguments);
                if (this.topic) {
                    this.own(
                        topic.subscribe(
                            this.topic,
                            function(selected) {
                                var dfmt;
                                if ( dojo_dateformat ) {
                                    dfmt = self._getFormat({selector: 'date'});
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
