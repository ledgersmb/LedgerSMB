define([
    'dijit/form/DateTextBox',
    'dojo/_base/declare'
    ],
    function(DateTextBox, declare) {
      return declare('lsmb/lib/DateTextBox',
        [DateTextBox],
        {
          postMixInProperties: function() {
            this.constraints.datePattern = lsmbConfig.dateformat;
            this.constraints.datePattern = this.constraints.datePattern.replace(/mm/, 'MM');
            this.inherited(arguments);
          }
        });
    }
    );
