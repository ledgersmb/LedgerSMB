
define(['lsmb/TabularForm',
        'dojo/_base/declare',
         'dijit/_WidgetBase',
         'dijit/_TemplatedMixin',
         'dijit/_WidgetsInTemplateMixin',
         'dijit/Registry',
         'dijit/_Container'],
       function(tabform, declare, _widgebase, _templatemixin, 
                _widgets_in_templat_mixin, registry, _container) {
             return declare ('lsmb/users/ChangePassword', 
                             [_widgetbase, templatemixin],
                 {
                    templateString :
'<div data-dojo-type="dojox.form.PasswordValidator" name="pwValidate">' +
  '<div id="pwtitle" width="100%" class="listheading">' +
  '<div id="pwfeedback" class="lsmb-feedback hidden"></div>' +
  '<div data-dojo-type="lsmb.TabularForm" name="pwcontainer">' +
    '<div class="input-line">' +
      '<div id="old-pw" data-dojo-type="password" pwType="old"></div>' +
    '</div><div class="input-line">' +
      '<div id="new-pw" data-dojo-type="password" pwType="new"></div>' +
    '</div><div class="input-line" id="pw-strength">' +
    '</div><div class="input-line">' +
      '<div id="verify-pw" data-dojo-type="password" pwType="verify" ></div>' +
    '</div><div class="input-line">' +
      '<button data-dojo-type="lsmb.PasswdButton" id="pw-change"></button>' +
    '</div><div class="input-line">' +
 '</div>' +
'</div>';
                   lstrings : {
                            'title':        "Change Password"
                            "old password": "Old Password",
                            "new password": "New password",
                            "verify":       "Verify",
                            "change":       "Change Password",
                            "strength":     "Strength" // TODO
                   };
                   buildRendering: function(){
                       this.inherited(arguments);
                       document.getElementById('pwtitle').innerHTML = this.lstrings.title;
                       r.byId('old-pw').set('title', this.lstrings['old password']);
                       r.byId('new-pw').set('title', this.lstrings['new password']);
                       r.byId('verify-pw').set('title', this.lstrings['verify password']);
                       r.byId('old-pw').set('title', this.lstrings.change;
                   }
                 }
             );
       }
);
