define([
    "dojo/_base/declare",
    "dojo/_base/event",
    "dojo/dom-attr",
    "dijit/form/Button",
    "lsmb/iframe",
    "dojo/dom-form",
    "dijit/registry"
],
       function(declare, event, domattr, Button, iframe, domform, registry) {
           return declare("lsmb/PrintButton",
                          [Button],
               {
                   minimalGET: true,
                   onClick: function(evt) {
                       var f = this.valueNode.form;
                       if (f.media.value == "screen") {
                           var data;

                           if (this.minimalGET) {
                               data = {
                                   action: this.get("value"),
                                   type: f.type.value,
                                   id: f.id.value,
                                   formname: f.formname.value,
                                   language_code: f.language_code.value,
                                   media: "screen",
                                   format: f.format.value
                               };
                               // Apparently, transactions do not include a
                               // 'vc' field; so, when we have one, add it.
                               // when we don't... don't.
                               if (f["vc"]) {
                                   data["vc"] = f.vc.value;
                               }
                           }
                           else {
                               data = domform.toObject(f);
                               data["action"] = this.get("value");
                           }

                           iframe(domattr.get(f, "action"), {
                               data: data
                           }).then(function(){
                               //success? do nothing
                           }, function(err) {
                               registry.byId("maindiv").report_request_error(err);
                           });
                           event.stop(evt);
                           return;
                       }

                       return this.inherited(arguments);
                   }
               });
       });
