define([
    "dijit/form/Form",
    "dojo/_base/declare",
    "dijit/registry",
    ],
       function(Form, declare, registry) {
           return declare("lsmb/setup/upgrade_info",
                          [Form],
              {
                  startup: function() {
                      var self = this;
                      this.inherited(arguments);
                      var button = registry.byId("button-upgrade-action");
                      button.attr("disabled", !self.isValid()); // set initial state
                        button.connect(self, "onValidStateChange", function(state){
                            button.attr("disabled", !state);
                        });
                  },
              });
       }
    );
