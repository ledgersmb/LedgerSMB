define([
    'dojo/store/Memory',
    'dojo/store/Observable',
    'dojo/request',
    'dojo/_base/array'
    ], function(
      Memory,
      Observable,
      request,
      array
      ){
    var store = new Observable(new Memory({
      idProperty: 'text'
    }));

    request.get('journal.pl?action=chart_json',{
        handleAs: 'json'
    }).then(
        function (results) {
          array.forEach(results, function(item){
            item.text = item.accno + '--' + item.description;
            store.put(item);
          });
        },
        console.log
        );
     return store;
});
