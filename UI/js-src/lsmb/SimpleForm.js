define([
    "dijit/form/Form",
    "dojo/_base/declare",
    ],
       function(Form, declare) {
           /* The purpose of the SimpleForm is to be a regular dijit/form/Form,
              enhanced with the standard behaviours LedgerSMB wants in its
              application, such as form validation.

              Note that in the usual use-case, you want the more extensively
              adapted lsmb/Form, which uses asynchronous requests to submit
              form content, as expected in the application's #maindiv

              Concluding: you only want to use this class in specific cases.
            */
           return declare("lsmb/SimpleForm", [Form],
              {
                  onSubmit: function(evt) {
                      return this.validate();
                  },
              });
       }
    );
