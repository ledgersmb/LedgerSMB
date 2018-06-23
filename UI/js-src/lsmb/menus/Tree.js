define(["dojo/_base/declare",
        "dojo/on",
        "dojo/_base/lang",
        "dojo/_base/event",
        "dojo/mouse",
        "dojo/_base/array",
        "dojo/store/JsonRest", "dojo/store/Observable",
        "dojo/store/Memory",
        "dijit/Tree", "dijit/tree/ObjectStoreModel",
        "dijit/registry", "dojo/dom-class"
       ], function(declare, on, lang, event, mouse, array,
                   JsonRest, Observable, Memory, Tree, ObjectStoreModel,
                   registry, domClass
){
        // set up the store to get the tree data, plus define the method
        // to query the children of a node
        var restStore = new JsonRest({
            target:      "menu.pl?action=menuitems_json",
            idProperty: "id"
        });
        var memoryStore = new Memory({idProperty: "id"});
        memoryStore = new Observable(memoryStore);

        // create model to interface Tree to store
        var model = new ObjectStoreModel({
            store: memoryStore,
            labelAttr: 'label',
            mayHaveChildren: function(item){ return item.menu; },
            getChildren: function(object, onComplete, onError){
                restStore.query({}).then(
                    function(items){
                        memoryStore.setData(items);
                        onComplete(memoryStore.query({parent: object.id}));
                    }, function(){ onError(); });
            },
            getRoot: function(onItem, onError){
                onItem({ id: 0 });
            }
        });

    return declare("lsmb/menus/Tree", [Tree], {
        model: model,
        showRoot: false,
        openOnClick: true,
        postCreate: function() {
            this.inherited(arguments);

            var self = this;
            this.onLoadDeferred.then(function(){
                domClass.add(self.domNode, "done-parsing");
            });
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
                var mainDiv = registry.byId("maindiv");
                mainDiv.load_link(url);
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

