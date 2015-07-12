define([
    'dijit/form/CheckBox',
    'dojo/_base/declare',
    'dojo/on',
    'dojo/dom',
    'dojo/dom-class',
    'dojo/ready'
], function(
    CheckBox,
    declare,
    on,
    dom,
    domClass,
    ready){
    return declare('lsmb/journal/fx_checkbox',[CheckBox],{
        postCreate: function() {
            var self = this;
            this.inherited(arguments);
            on(this.domNode,'click',
               function() {
                   if (self.checked) {
                       domClass.add('transaction-table','fx-transaction');
                       domClass.remove('transaction-table','no-fx-transaction');
                   }
                   else {
                       domClass.add('transaction-table','no-fx-transaction');
                       domClass.remove('transaction-table','fx-transaction');
                   }
               });
        }
    });
});
