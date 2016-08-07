
define(['lsmb/TabularForm',
        'dojo/_base/declare',
         'dijit/_WidgetBase',
         'dijit/_TemplatedMixin',
         'dijit/_WidgetsInTemplateMixin',
         'dijit/_Container'],
       function(tabform, declare, _widgebase, _templatemixin, 
                _widgets_in_templat_mixin, _container) {
             return declare ('lsmb/users/ChangePassword', 
                             [_widgetbase, templatemixin],
                 {
                    templateString = 
'<div data-dojo-type="dojox.form.PasswordValidator" name="pwValidate">' +
  '<div data-dojo-type="lsmb.TabularForm" name="pwcontainer">' +
    '<div class="input-line">' +
      '<input type="password" pwType="old" />' +
    '</div><div class="input-line">' +
      '<input type="password" pwType="new" />' +
    '</div><div class="input-line">' +
    '</div><div class="input-line">' +
      '<input type="password" pwType="verify" />' +
    '</div><div class="input-line">' +
    '</div><div class="input-line">' +
 '</div>' +
'</div>';
                 }
             );
       }
);
