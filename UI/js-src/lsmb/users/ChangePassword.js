define(['lsmb/TabularForm',
        'dojo/_base/declare',
         'dijit/_WidgetBase',
         'dijit/_TemplatedMixin',
         'dijit/_WidgetsInTemplateMixin',
         'dijit/layout/ContentPane',
         'dijit/registry',
         'dojo/on',
         'dijit/form/TextBox',
         'dijit/form/Button',
         'dijit/_Container'],
       function(tabform, declare, _widgetbase, _templatemixin, 
                _widget_parser, cp, registry, on, textbox, button, _container) {
             return declare ('lsmb/users/ChangePassword', 
                             [_widgetbase, _templatemixin, _widget_parser],
                 {
                    templateString : '\
  <div>\
  <div id="pwtitle" width="100%" class="listheading"></div> \
  <div id="pwfeedback" data-dojo-type="dijit/layout/ContentPane" data-dojo-attach-point="feedback">&nbsp;</div> \
  <div data-dojo-type="lsmb/TabularForm" id="pwcontainer" data-dojo-props="cols:1"> \
    <div class="input-line"> \
      <input id="old-pw" data-dojo-type="dijit/form/TextBox" type="password" pwType="old" data-dojo-attach-point="oldpw" /> \
    </div><div class="input-line"> \
      <div id="new-pw" data-dojo-type="dijit/form/TextBox" type="password" pwType="new" data-dojo-attach-point="newpw"></div> \
    </div><div class="input-line" id="pw-strength-container"> \
        <div id="pw-strength" data-dojo-type="dijit/layout/ContentPane">0</div>\
    </div><div class="input-line"> \
      <div id="verify-pw" data-dojo-type="dijit/form/TextBox" type="password" pwType="verify" data-dojo-attach-point="verified"></div> \
    </div><div class="input-line"> \
      <button data-dojo-type="dijit/form/Button" id="pw-change" data-dojo-attach-point="submitbutton"></button> \
    </div><div class="input-line"> \
</div></div>',
                   _lstrings : {
                            'title':        "Change Password",
                            "old password": "Old Password",
                            "new password": "New password",
                            "verify":       "Verify",
                            "change":       "Change Password",
                            'no-oldpw':     "No Old Password",
                            "strength":     "Strength" 
                   },
                   lstrings : {},
                   text(to_translate){
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
                       document.getElementById('pwtitle').innerHTML = this.lstrings.title;
                       I = this;
                       on(this.newpw, 'keypress', function(){
                          I.setStrengthClass()
                       });

                       registry.byId('old-pw').set('title', this.text('old password'));
                       registry.byId('new-pw').set('title', this.text('new password'));
                       registry.byId('verify-pw').set('title', this.text('verify'));
                       registry.byId('pw-change').set('innerHTML', this.text('change'));
                       registry.byId('pw-strength').set('title', this.text('strength'));
                       on(this.submitbutton, 'click', function(){I.submit_form()});
                       this.inherited(arguments);
                   },
                   scorePassword: function() {
                        var pass = registry.byId('new-pw').get('value');
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
                            variationCount += (variations[check] == true) ? 1 : 0;
                        }
                        score += (variationCount - 1) * 10;

                        return parseInt(score);

                   },
                   setStrengthClass: function() {
                        var score = this.scorePassword();
                        var bgclass='';
                        if (score > 80)
                            bgclass = "strong";
                        else if (score > 60)
                            bgclass = "good";
                        else if (score >= 30)
                            bgclass = "weak";
                        var elem = registry.byId('pw-strength');
                        elem.set('class', bgclass);
                        elem.set('innerHTML', score);

                  },
                  submit_form: function() {
                      var I = this;
                      require(
                           ['dojo/request'],
                           function(r) {
                              console.log('change_pw clicked');
                              var login = document.getElementById('username').value;
                              var old_password = I.oldpw.get('value');
                              var new_password = I.newpw.get('value');
                              var confirm_pass = I.verified.get('value');
                              if (old_password == '' || new_password == '')
                                   return I.setFeedback(0, I.text('Password Required'));
                              if (new_password != confirm_pass)
                                   return I.setFeedback(0, I.text('Confirmation did not match'));
                              r('user.pl',
                                   {
                                      'data': {
                                        'action': 'change_password',
                                        'old_password': old_password,
                                        'new_password': new_password,
                                        'confirm_password': confirm_pass
                                  },
                                 'method': 'POST',
                             }).then(function(response){
                                I.setFeedback(1, I.text("Password Changed"));
                             }).otherwise(function(err) {
                                 if (err.response.status != 200){
                                    if (err.response.status != '500'){
                                         I.setFeedback(0, I.text("Bad username/Password"));
                                    } else {
                                         I.setFeedback(0,I.text('Company does not exist.'));
                                    }
                                  }
                              });
                          });
                  },
                  setFeedback: function(success, message) {
                        if (success)
                             this.feedback.set('class', 'success');
                        else
                             this.feedback.set('class', 'failure');
                        this.feedback.set('innerHTML', message);
                  }
               }
             );
       }
);
