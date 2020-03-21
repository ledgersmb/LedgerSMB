define([
    "dojo/_base/declare",
    "dojo/_base/event",
    "dijit/form/Button",
    "dojo/request/xhr",
    "dojo/dom-form",
    "dojo/dom-attr",
    "dijit/registry"
],
       function(declare, event, Button, xhr, domform, domattr, registry) {
           return declare("lsmb/payments/PostPrintButton",
                          [Button],
               {
                   onClick: function(evt) {
                       var f = this.valueNode.form;
                       event.stop(evt);

                       var data = domform.toObject(f);
                       data["action"] = this.get("value");

                       xhr(domattr.get(f, "action"), {
                           "method": "POST",
                           "data": data,
                           "handleAs": "blob"
                       }).then(
                           function(blob) {
                               // IE doesn't allow using a blob object directly
                               // as link href; instead it is necessary to use
                               // msSaveOrOpenBlob
                               if (window.navigator
                                   && window.navigator.msSaveOrOpenBlob) {
                                   window.navigator.msSaveOrOpenBlob(
                                       blob, "print-payment.html");
                                   return;
                               }

                               // For other browsers:
                               // Create a link pointing to the ObjectURL
                               // containing the blob.
                               const data = window.URL.createObjectURL(blob);
                               var link = document.createElement('a');
                               link.href = data;
                               link.download="print-payment.html";
                               link.click();
                               setTimeout(function(){
                                   // For Firefox it is necessary to delay
                                   // revoking the ObjectURL
                                   window.URL.revokeObjectURL(data);
                               }, 100);
                               registry.byId("maindiv").load_link(
                                   "payment.pl?action=payment&account_class="
                                       + data["account_class"]
                                       + "&type=" + data["type"]);
                           },
                           function(err) {
                               registry.byId("maindiv")
                                   .report_request_error(err);
                           });
                   }
               });
       });
