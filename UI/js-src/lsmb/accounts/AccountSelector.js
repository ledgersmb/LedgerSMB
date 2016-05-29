define([
    'dijit/form/FilteringSelect',
    'dojo/_base/declare',
    'lsmb/accounts/AccountStore'
    ], function(
      Select,
      declare,
      store
      ){
        var mySelect = new declare('lsmb/accounts/AccountSelector',[Select],{
          store:  store,
          queryExpr: "*${0}*",
          style: 'width: 300px',
          query: {'charttype': 'A'},
          highlightMatch: 'all',
          searchAttr: 'text',
          autoComplete: false,
          initialValue:null,
          constructor:function(){
           this.inherited(arguments);
//           console.log('arguments',arguments);
           this.initialValue=arguments[0].value;
          },
          postCreate:function(){
           var mySelf=this;
           this.inherited(arguments);
           store.emitter.on("accountstore_loadcomplete",function(){
//            console.log('AccountSelector accountstore_loadcomplete mySelf=',mySelf);
            mySelf.set('value',mySelf.initialValue);
           });
          }//postCreate
        });
        return mySelect;
      });
