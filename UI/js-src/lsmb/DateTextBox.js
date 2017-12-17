define([
    "dijit/form/DateTextBox",
    "dojo/date/locale",
    "dojo/i18n",
    "dojo/_base/declare"
    ],
       function(DateTextBox, locale, i18n, declare) {
           var isoDate = /^\d\d\d\d-\d\d-\d\d$/;
      return declare("lsmb/DateTextBox",
        [DateTextBox],
        {
          _formattedValue: null,
          constructor: function(params, srcNodeRef) {
            this._formattedValue = srcNodeRef.value;

            /* Provide default 'old code' doesn't include in its templates */
            if (! params.constraints) {
               params.constraints = { };
            }
            if (! params.constraints.datePattern
                 && lsmbConfig.dateformat) {
              params.constraints.datePattern =
                lsmbConfig.dateformat.replace(/mm/,"MM");
            }
            if (! params.placeholder && lsmbConfig.dateformat) {
               params.placeholder = lsmbConfig.dateformat;
            }
            // end of 'old code' support block

            // retrieve format to add it as the placeholder
            // (unless there's a placeholder already)
            if (! params.placeholder) {
               var l = i18n.normalizeLocale(params.locale),
                   formatLength = params.formatLength || 'short',
                   bundle = locale._getGregorianBundle(l);

               if(params.constraints.selector == "year") {
                  params.placeholder = bundle["dateFormatItem-yyyy"] || "yyyy";
               }
               else if(params.constraints.selector == "time") {
                  params.placeholder = params.constraints.timePattern
                       || bundle["timeFormat-"+formatLength];
               }
               else {
                  params.placeholder = params.constraints.datePattern
                       || bundle["dateFormat-"+formatLength];
               }
               params.placeholder =
                  params.placeholder.replace(/M/g, 'm').replace(/y/g, 'yy');
            }
          },
          postMixInProperties: function() {
            this.inherited(arguments);
            if (this._formattedValue &&
                (! this.value || ! isoDate.test(this.value))) {
              /* This code purely compensates for the fact that most LedgerSMB
                 server code sends the date according to the user's selected
                 preference, instead of in ISO format, which the widget
                 expects */
              this.value = this.parse(this._formattedValue, this.constraints);
            }
          },
            parse: function(value, constraints) {
                if (! isoDate.test(value)) {
                    return this.inherited(arguments);
                }
                return locale.parse(value,
                                    { datePattern: "yyyy-MM-dd", selector: "date" });
            }
        });
    }
    );
