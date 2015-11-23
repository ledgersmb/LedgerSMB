define([
    'dijit/form/FilteringSelect',
    'dojo/_base/declare',
    'lsmb/parts/PartStore'
    ], function(
      Select,
      declare,
      store
      ){
        var mySelect = new declare('lsmb/parts/PartSelector',[Select],{
          store:  store,
          queryExpr: "*${0}*",
          style: 'width: 300px',
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
           store.emitter.on("partstore_loadcomplete",function(){
//            console.log('PartSelector accountstore_loadcomplete mySelf=',mySelf);
            mySelf.set('value',mySelf.initialValue);
           });
          }//postCreate
        });
        return mySelect;
      });
