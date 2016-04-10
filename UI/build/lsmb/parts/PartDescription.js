//>>built
define("lsmb/parts/PartDescription",["dijit/form/Textarea","dojo/_base/declare","dojo/topic"],function(a,b,c){return b("lsmb/parts/PartsDescription",[a],{linenum:null,height:null,startup:function(){var a=this;this.own(c.subscribe("/invoice/part-select/"+this.linenum,function(b){a.set("value",b.description)}))}})});
//# sourceMappingURL=PartDescription.js.map