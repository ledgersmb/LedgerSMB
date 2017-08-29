define(["dojo/_base/declare",
        "dojo/on",
        "dojo/_base/lang",
        "dojo/_base/event",
        "dojo/mouse",
        "dojo/_base/array",
        "dojo/store/JsonRest", "dojo/store/Observable",
        "dojo/store/Memory", "dojo/store/Cache",
        "dijit/Tree", "dijit/tree/ObjectStoreModel"
       ], function(declare, on, lang, event, mouse, array,
                   JsonRest, Observable, Memory, Cache, Tree, ObjectStoreModel
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
        postCreate: function() {
            this.inherited(arguments);

            this.own(
                on(this.containerNode, "mousedown",
                   lang.hitch(this, this.__onClick)));
        },
        onClick: function(item, node, event){
            // regular handling of non-leafs
            if (item.menu) return;

            // for leafs, either open in the current application,
            // or open a new window, depending on the trigger.
            var url = '',
                newWindow = ((mouse.isLeft(event)
                              && (event.ctrlKey || event.metaKey))
                             || (mouse.isMiddle(event))
                             || array.some( item.args,
                                            function (q) {
                                                return ("new=1" == q)
                                            }));
            if ( item.module ) {
                url += item.module + "?";
                url += item.args.join("&");
            }
            if ( newWindow ) {
                // Simulate a target="_blank" attribute on an A tag
                window.open(location.origin + location.pathname
                            + location.search + '#' + url, "_blank");
            }
            else {
                location.hash = url;
            }
        },
        __onClick: function(e) {
            // simulate "click opening in background tab"
            // (Ctrl+LeftMouse or MiddleMouse)
            if (mouse.isLeft(e) && !(e.ctrlKey || e.metaKey)) return;

            event.stop(e);
            e.preventDefault();

            var node = dijit.getEnclosingWidget(e.target);
            var item = node.item;
            this.onClick(item, node, e);
        }
    });
});

