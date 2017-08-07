define([
    "dojo/store/Memory",
    "dojo/store/Observable",
    "dojo/request",
    "dojo/_base/array",
     "dojo/Evented"
    ], function(
      Memory,
      Observable,
      request,
      array,
      Evented
      ){
    var store = new Observable(new Memory({
      idProperty: "text",
      emitter:new Evented()
    }));

    request.get("menu.pl?action=menuitems_json",{
        handleAs: "json"
    }).then(
        function (results) {
          array.forEach(results, function(item){
//            item.text = item.accno + "--" + item.description;
            store.put(item);
          });
         console.log("MenuStore emitting loadclomplete");
         store.emitter.emit("menustore_loadcomplete",{bubbles: true, cancelable: false});
        },
        function(error){
            console.error(error);
        }
    );
    return store;
});
