define([
    "dijit/form/DateTextBox",
    "dojo/date/locale",
    "dojo/_base/declare"
    ],
       function(DateTextBox, locale, declare) {
           var isoDate = /^\d\d\d\d-\d\d-\d\d$/;
      return declare("lsmb/DateTextBox",
        [DateTextBox],
        {
          _formattedValue: null,
          constructor: function(params, srcNodeRef) {
  // this is a workaround for https://github.com/ledgersmb/LedgerSMB/issues/2270
            this._formattedValue = srcNodeRef.value;

            /* Provide default 'old code' doesn't include in its templates */
            if (! params.constraints) {
               params.constraints = { };
            }
            if (! params.constraints.datePattern) {
              params.constraints.datePattern =
                lsmbConfig.dateformat.replace(/mm/,"MM");
            }
            if (! params.placeholder) {
               params.placeholder = lsmbConfig.dateformat;
            }
            // end of 'old code' support block

            this.inherited(arguments);
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
   // this is a workaround for https://github.com/ledgersmb/LedgerSMB/issues/2270
               if (! isoDate.test(value)) {
                    return this.inherited(arguments);
                }
                return locale.parse(value,
                                    { datePattern: "yyyy-MM-dd", selector: "date" });
            }
        });
    }
    );
