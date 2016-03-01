//>>built
define("lsmb/PublishCheckBox",["dojo/_base/declare","dojo/on","dojo/topic","dijit/form/CheckBox"],function(a,c,d,e){return a("lsmb/PublishCheckbox",[e],{topic:"",publish:function(b){d.publish(this.topic,b)},postCreate:function(){var b=this;this.own(c(this,"change",function(a){b.publish(a)}))}})});
//# sourceMappingURL=PublishCheckBox.js.map