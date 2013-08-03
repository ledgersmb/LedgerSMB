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
          autoComplete: false

        });
        return mySelect;
      });
