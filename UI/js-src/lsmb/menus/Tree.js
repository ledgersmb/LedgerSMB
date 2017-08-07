define(["dojo/_base/declare",
        "dojo/_base/array",
        "dojo/when",
    "dojo/store/JsonRest", "dojo/store/Observable",
    "dojo/store/Memory", "dojo/store/Cache",
    "dijit/Tree", "dijit/tree/ObjectStoreModel"
       ], function(declare, array, when, JsonRest, Observable,
    Memory, Cache,
    Tree, ObjectStoreModel
){
        // set up the store to get the tree data, plus define the method
        // to query the children of a node
        var restStore = new JsonRest({
            target:      "menu.pl?action=menuitems_json&",
            idProperty: "id"
        });
        var memoryStore = new Memory({idProperty: "id"});
        var store = new Cache(restStore, memoryStore);

        // initialize the store with the full menu
        var results = store.query({});

        // give store Observable interface so Tree can track updates
        store = new Observable(store);

        // create model to interface Tree to store
        var model = new ObjectStoreModel({
            store: store,
            labelAttr: 'label',
            mayHaveChildren: function(item){ return item.menu; },
            getChildren: function(object, onComplete, onError){
                onComplete(memoryStore.query({parent: object.id}));
             },
            getRoot: function(onItem, onError){
                store.get(0).then(onItem, onError);
            }
        });

    return declare("lsmb/menus/Tree", [Tree], {
            model: model,
            showRoot: false,
            openOnClick: true,
            onClick: function(item){
                var url = '';
                if ( item.module ) {
                    url += item.module + "?";
                    url += item.args.join("&");
                }
                if ( array.some( item.args,
                                 function (q) {
                                     return ("new=1" == q);
                                 }) ) {
                    // Simulate a target="_blank" attribute on an A tag
                    window.open(location.origin + location.pathname + location.search + '#' + url);
                }
                else {
                    location.hash = url;
                }
            }
        });
});

