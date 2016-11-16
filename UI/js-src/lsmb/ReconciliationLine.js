define("lsmb/ReconciliationLine",
       ["dojo/_base/declare",
        "dojo/on",
        "dijit/registry",
        "dojo/dom-class",
        "dijit/form/CheckBox"],
       function(declare, on, registry, domClass, CheckBox) {
           return declare("lsmb/ReconciliationLine", [CheckBox], {
               publish: function(targetValue) {
                   var id = this.id.replace("cleared-","recon-line-");
                   if ( ! id ) return;
                   if (targetValue) {
                       domClass.add(id, "active");
                       domClass.remove(id, "record");
                   } else {
                       domClass.add(id, "record");
                       domClass.remove(id, "active");
                   }
                   document.getElementById("action-update-recon-set").click();
               },
               postCreate: function() {
                   var self = this;
                   this.inherited(arguments);
                   this.own(
                       on(this, "change",
                          function(targetValue) {
                              self.publish(targetValue);
                          })
                   );
               }
           });
       });
