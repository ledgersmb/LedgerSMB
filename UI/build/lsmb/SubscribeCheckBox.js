//>>built
define("lsmb/SubscribeCheckBox",["dojo/_base/declare","dojo/on","dojo/topic","dijit/form/CheckBox"],function(b,e,c,d){return b("lsmb/SubscribeCheckBox",[d],{topic:"",update:function(a){this.set("checked",a)},postCreate:function(){var a=this;this.inherited(arguments);this.own(c.subscribe(a.topic,function(b){a.update(b)}))}})});
//# sourceMappingURL=SubscribeCheckBox.js.map