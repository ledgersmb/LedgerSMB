//>>built
define("lsmb/DateTextBox",["dijit/form/DateTextBox","dojo/_base/declare"],function(a,b){return b("lsmb/DateTextBox",[a],{postMixInProperties:function(){this.constraints.datePattern=lsmbConfig.dateformat;this.constraints.datePattern=this.constraints.datePattern.replace(/mm/,"MM");this.inherited(arguments)}})});
//# sourceMappingURL=DateTextBox.js.map