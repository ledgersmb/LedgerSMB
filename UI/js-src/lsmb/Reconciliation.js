define("lsmb/Reconciliation",
       ["dojo/_base/declare",
        "dojo/topic",
        "dojo/query",
        "lsmb/Form",
        "dijit/_Container",
        "dojo/NodeList-dom",     // To load extensions in query
        "dojo/domReady!"],
       function(declare, Topic, Query, Form, _Container) {
           return declare("lsmb/Reconciliation", [Form, _Container], {
               update: function(targetValue, prefix) {
                   Query(prefix + " tbody tr.record").style("display", targetValue ? "" : "none");
               },
               postCreate: function() {
                   var self = this;
                   this.inherited(arguments);
                   Topic.subscribe("ui/reconciliation/report/b_cleared_table",
                        function(targetValue) {
                            self.update(targetValue,"#cleared-table");
                        });
                   Topic.subscribe("ui/reconciliation/report/b_mismatch_table",
                        function(targetValue) {
                            self.update(targetValue,"#mismatch-table");
                        });
                   Topic.subscribe("ui/reconciliation/report/b_outstanding_table",
                        function(targetValue) {
                            self.update(targetValue,"#outstanding-table");
                        });
               }
           });
       });
