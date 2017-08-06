define(["dojo/_base/declare",
    "dojo/store/JsonRest", "dojo/store/Observable",
    "dojo/store/Memory", "lsmb/menus/Cache",
    "dijit/Tree", "dijit/tree/ObjectStoreModel"
], function(declare, JsonRest, Observable,
    Memory, Cache,
    Tree, ObjectStoreModel
){
        // set up the store to get the tree data, plus define the method
        // to query the children of a node
        var restStore = new JsonRest({
            target:      "menu.pl?action=menuitems_json",
            idProperty: "id"
        });
        var memoryStore = new Memory({idProperty: "id"});
        var store = new Cache(restStore, memoryStore);
        // Overwrite the standard getter

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
                // get the root object, we will do a get() and callback the result
                this.store.get(0).then(onItem, onError);
            }
        });

    return declare("lsmb/menus/MenuRestStore", [Tree], {
            model: model,
            persist: false,
            autoExpand: false,
            showRoot: false,
            openOnClick: true,
            getIconClass: function(/*dojo.data.Item*/ item, /*Boolean*/ opened){
                return (!item || item.menu) ? (opened ? "dijitFolderOpened" : "dijitFolderClosed") : "dijitLeaf"
            },
            onClick: function(item){
                var url = '';
                if ( item.module ) {
                    url += item.module + "?";
                    url += item.args.join("&");
                }
                url += ('New Window' == item.label) ? "&target='new'"
                    : "";
                location.hash = url;
            }
        });
});

