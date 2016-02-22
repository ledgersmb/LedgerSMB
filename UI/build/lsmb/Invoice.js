//>>built
require(["dojo/_base/declare","dijit/registry","dojo/on","lsmb/Form","dijit/_Container"],function(a,b,c,d,e){return a("lsmb/Invoice",[d,e],{_update:function(){this.clickedAction="update";this.submit()},startup:function(){var a=this;this.inherited(arguments);this.own(c(b.byId("invoice-lines"),"changed",function(){a._update()}))}})});
//# sourceMappingURL=Invoice.js.map