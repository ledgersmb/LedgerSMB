define([
    "dijit/form/Form",
    "dojo/_base/declare",
    "dojo/_base/event",
    "dojo/on",
    "dojo/hash",
    "dojo/dom-attr",
    "dojo/dom-form",
    "dojo/query",
    "dijit/registry"
    ],
       function(Form, declare, event, on, hash, domattr, domform,
                query, registry) {
           var c = 0;
           return declare("lsmb/Form",
                          [Form],
              {
                  clickedAction: null,
                  startup: function() {
                      var self = this;
                      this.inherited(arguments);

                      // <button> tags get rewritten to <input type="submit" tags...
                      query("input[type=\"submit\"]", this.domNode)
                          .forEach(function(b) {
                              on(b, "click", function(){
                                  self.clickedAction = domattr.get(b, "value");
                              });
                          });

                  },
                  onSubmit: function(evt) {
                      event.stop(evt);
                      this.submit();
                  },
                  submit: function() {
                      if (! this.validate())
                          return;

                      var method = (typeof this.method === "undefined")
                                 ? "GET"
                                 : this.method;
                      var url = this.action;
                      var options = { "handleAs": "text" };
                      if ("get" === method.toLowerCase()){
                          if (!url) {
                              alert('Form contains no action. Please file a bug');
                              return false;
                          }
                          c++;
                          var qobj = domform.toQuery(this.domNode);
                          qobj = "action=" + this.clickedAction + "&" + qobj;
                          url = url + "?" + qobj + '#' + c.toString(16);
                          hash(url); // add GET forms to the back button history
                      } else {
                          options["method"] = method;
                          if ("multipart/form-data" == this.domNode.enctype) {
                              options["data"] = new FormData(this.domNode);
                              // FF doesn't add the clicked button
                              options["data"].append('action',
                                                     this.clickedAction);
                          } else {
                              // old code (Form.pm) wants x-www-urlencoded
                              options["data"] = "action="+this.clickedAction
                                  + "&" + domform.toQuery(this.domNode);
                          }
                          registry.byId("maindiv").load_form(url, options);
                      }
                  }
              });
       }
    );
