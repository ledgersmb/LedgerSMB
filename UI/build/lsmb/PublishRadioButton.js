//>>built
define("lsmb/PublishRadioButton",["dojo/_base/declare","dojo/on","dojo/topic","dijit/form/RadioButton"],function(a,b,c,d){return a("lsmb/PublishRadioButton",[d],{topic:"",publish:function(){c.publish(this.topic,this.value)},postCreate:function(){var a=this;this.own(b(this.domNode,"change",function(){a.publish()}))}})});
//# sourceMappingURL=PublishRadioButton.js.map