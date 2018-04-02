define([
    "lsmb/FilteringSelect",
    "dojo/_base/declare",
    "lsmb/accounts/AccountRestStore"
    ], function(
      Select,
      declare,
      store
      ){
        var mySelect = new declare("lsmb/accounts/AccountSelector",[Select],{
          store:  store,
          queryExpr: "*${0}*",
          style: "width: 300px",
//          query: {"charttype": "A"},
          highlightMatch: "all",
            searchAttr: "label",
            labelAttr: "label",
          autoComplete: false,
          initialValue:null,
          constructor:function(){
           this.inherited(arguments);
           this.initialValue=arguments[0].value;
          }
        });
        return mySelect;
      });
