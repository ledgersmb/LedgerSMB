/** @format */

define("lsmb/Reconciliation", [
    "dojo/_base/declare",
    "dojo/topic",
    "dojo/query",
    "lsmb/Form",
    "dijit/_Container",
    "dojo/NodeList-dom" // To load extensions in query
], function (declare, topic, query, Form, _Container) {
    return declare("lsmb/Reconciliation", [Form, _Container], {
        update: function (targetValue, prefix) {
            query(prefix + " tbody tr.record").style(
                "display",
                targetValue ? "" : "none"
            );
        },
        postCreate: function () {
            var self = this;
            this.inherited(arguments);
            topic.subscribe(
                "ui/reconciliation/report/b_cleared_table",
                function (targetValue) {
                    self.update(targetValue, "#cleared-table");
                }
            );
            topic.subscribe(
                "ui/reconciliation/report/b_mismatch_table",
                function (targetValue) {
                    self.update(targetValue, "#mismatch-table");
                }
            );
            topic.subscribe(
                "ui/reconciliation/report/b_outstanding_table",
                function (targetValue) {
                    self.update(targetValue, "#outstanding-table");
                }
            );
        }
    });
});
