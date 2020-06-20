/** @format */
/* global dojo, dijit */

define(["dojo/_base/declare", "dijit/form/Button"], function (declare, button) {
   return declare("lsmb/payments/ToggleIncludeButton", [button], {
      onClick: function () {
         dojo
            .query('input[name^="checkbox_"]', this.valueNode.form)
            .forEach(function (node) {
               var n = dijit.getEnclosingWidget(node);
               n.set("checked", !n.get("checked"));
            });
      }
   });
});
