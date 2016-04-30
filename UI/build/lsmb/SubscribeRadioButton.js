//>>built
define("lsmb/SubscribeRadioButton",["dojo/_base/declare","dojo/on","dojo/topic","dijit/form/RadioButton"],function(b,e,c,d){return b("lsmb/SubscribeRadioButton",[d],{topic:"",update:function(a){this.set("checked",a)},postCreate:function(){var a=this;this.inherited(arguments);this.own(c.subscribe(a.topic,function(b){a.update(b)}))}})});
//# sourceMappingURL=SubscribeRadioButton.js.map