define(["lsmb/TabularForm",
        "dojo/_base/declare",
         "dijit/_WidgetBase",
         "dijit/_TemplatedMixin",
         "dijit/_WidgetsInTemplateMixin",
         "dijit/layout/ContentPane",
         "dijit/registry",
         "dojo/on",
         "dijit/form/TextBox",
         "dijit/form/Button",
         "dojo/text!./templates/PasswordChange.html",
         "dojo/request",
         "dijit/_Container"],
       function(tabform, declare, _widgetbase, _templatemixin,
                _widget_parser, cp, registry, on, textbox, button,
                template, request, _container) {
             return declare("lsmb/users/ChangePassword",
                             [_widgetbase, _templatemixin, _widget_parser],
                 {
                    templateString: template,
                   _lstrings: {
                            "title":        "Change Password",
                            "old password": "Old Password",
                            "new password": "New password",
                            "verify":       "Verify",
                            "change":       "Change Password",
                            "no-oldpw":     "No Old Password",
                            "strength":     "Strength"
                   },
                   lstrings: {},
                   text: function(to_translate){
                       if (undefined === this.lstrings[to_translate])
                          return to_translate;
                       return this.lstrings[to_translate];
                   },
                   startup: function(){
                       for (str in this._lstrings){
                           if (this.lstrings[str]){
                               continue;
                           }
                           this.lstrings[str] = this._lstrings[str];
                       }
                       document.getElementById("pwtitle").innerHTML = this.lstrings.title;
                       I = this;
                       on(this.newpw, "keypress", function(){
                          I.setStrengthClass()
                       });

                       registry.byId("old-pw").set("title", this.text("old password"));
                       registry.byId("new-pw").set("title", this.text("new password"));
                       registry.byId("verify-pw").set("title", this.text("verify"));
                       registry.byId("pw-change").set("innerHTML", this.text("change"));
                       registry.byId("pw-strength").set("title", this.text("strength"));
                       on(this.submitbutton, "click", function(){I.submit_form()});
                       this.inherited(arguments);
                   },
                   scorePassword: function() {
                        var pass = registry.byId("new-pw").get("value");
                        var score = 0;
                        if (!pass)
                            return score;
                        var letters = new Object();
                        for (var i=0; i<pass.length; i++) {
                            letters[pass[i]] = (letters[pass[i]] || 0) + 1;
                            score += 5.0 / letters[pass[i]];
                        }
                        var variations = {
                            digits: /\d/.test(pass),
                             lower: /[a-z]/.test(pass),
                             upper: /[A-Z]/.test(pass),
                          nonWords: /\W/.test(pass)
                        }
                        variationCount = 0;
                        for (var check in variations) {
                            variationCount += (variations[check] === true) ? 1 : 0;
                        }
                        score += (variationCount - 1) * 10;

                        return parseInt(score);

                   },
                   setStrengthClass: function() {
                        var score = this.scorePassword();
                        var bgclass="";
                        if (score > 80)
                            bgclass = "strong";
                        else if (score > 60)
                            bgclass = "good";
                        else if (score >= 30)
                            bgclass = "weak";
                        var elem = registry.byId("pw-strength");
                        elem.set("class", bgclass);
                        elem.set("innerHTML", score);

                  },
                  submit_form: function() {
                      var I = this;
                      var r = request;
                      console.log("change_pw clicked");
                      var login = document.getElementById("username").value;
                      var old_password = I.oldpw.get("value");
                      var new_password = I.newpw.get("value");
                      var confirm_pass = I.verified.get("value");
                      if (old_password === "" || new_password === "")
                           return I.setFeedback(0, I.text("Password Required"));
                      if (new_password !== confirm_pass)
                           return I.setFeedback(0, I.text("Confirmation did not match"));
                      r("user.pl", {
                              "data": {
                                "action": "change_password",
                                "old_password": old_password,
                                "new_password": new_password,
                                "confirm_password": confirm_pass
                              },
                              "method": "POST"
                     }).then(function(response){
                        I.setFeedback(1, I.text("Password Changed"));
                     }).otherwise(function(err) {
                         if (err.response.status != 200){
                            if (err.response.status != "500"){
                                 I.setFeedback(0, I.text("Bad username/Password"));
                            } else {
                                 I.setFeedback(0,I.text("Error changing password."));
                            }
                          }
                      });
          },
          setFeedback: function(success, message) {
                if (success)
                     this.feedback.set("class", "success");
                else
                     this.feedback.set("class", "failure");
                this.feedback.set("innerHTML", message);
          }
       }
     );
}
);
