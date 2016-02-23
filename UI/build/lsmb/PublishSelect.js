//>>built
define("lsmb/PublishSelect",["dojo/_base/declare","dojo/on","dojo/topic","dijit/form/Select"],function(a,c,d,e){return a("lsmb/PublishSelect",[e],{topic:"",publish:function(b){d.publish(this.topic,b)},postCreate:function(){var b=this;this.inherited(arguments);this.own(c(this,"change",function(a){b.publish(a)}))}})});
//# sourceMappingURL=PublishSelect.js.map