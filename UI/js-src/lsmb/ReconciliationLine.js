/** @format */

define("lsmb/ReconciliationLine", [
   "dojo/_base/declare",
   "dojo/on",
   "dojo/dom-class",
   "dijit/_WidgetBase",
   "dijit/_Container",
], function (declare, on, domClass, _WidgetBase, _Container) {
   return declare("lsmb/ReconciliationLine", [_WidgetBase, _Container], {
      _display: function (targetValue) {
         var id = this.id.replace("cleared-", "recon-line-");
         if (!id) {
            return;
         }
         if (targetValue) {
            domClass.add(id, "active");
            domClass.remove(id, "record");
         } else {
            domClass.add(id, "record");
            domClass.remove(id, "active");
         }
         document.getElementById("action-update-recon-set").click();
      },
      postCreate: function () {
         var self = this;
         this.inherited(arguments);
         this.own(
            on(this, "change", function (targetValue) {
               self._display(targetValue);
            })
         );
      }
   });
});
