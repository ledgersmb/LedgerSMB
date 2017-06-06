define(["dojo/_base/declare",
    "dojo/store/JsonRest", "dojo/store/Observable",
    "dojo/store/Memory", "lsmb/menus/Cache",
    "dijit/Tree", "dijit/tree/ObjectStoreModel",
    "dijit/Menu", "dijit/MenuSeparator", "dijit/PopupMenuItem",
    "dojo/when", "dojo/dom", "dojo/ready"
], function(declare, JsonRest, Observable,
    Memory, Cache,
    Tree, ObjectStoreModel,
    Menu, MenuSeparator, PopupMenuItem,
    when, dom, ready
){
  return declare(
    "lsmb/menus/MenuRestStore", [Menu], {
    postCreate: function() {
        // set up the store to get the tree data, plus define the method
        // to query the children of a node
        var restStore = new JsonRest({
            target:      "menu.pl?action=menuitems_json",
            idProperty: "id",
            _getTarget: function(id){
                return this.target;
            },
        });
        var memoryStore = new Memory({idProperty: "id"});
        var store = new Cache(restStore, memoryStore);
        // Overwrite the standard getter

        // give store Observable interface so Tree can track updates
        // store = new Observable(store);

        // create model to interface Tree to store
        var model = new ObjectStoreModel({
            store: store,
            // Utility routines
            mayHaveChildren: function(object){
                // if true, we might be missing the data, false and nothing should be done
                return ("children" in object) && object["children"] ;
            },
            getChildren: function(object, onComplete, onError){
                // Supply a getChildren() method to store for the data model where
                // children objects point to their parent (aka relational model)
                // return this.query({parent: object.id});
                // That is the standard way but querying the cache will query JSON
                // If Cache were to be fixed, then we could simplify the
                // code below, rely on above mechanism and remove Perl & SQL routines
                var kids;
                if ( object.children ) {
                    kids = [];
                    for ( var i = 0 ; i < object.children.length ; i++ ) {
                        when(this.store.get(object.children[i]), function(item) {
                            var url = "";
                            if ( item.module ) {
                                url += item.module + "?login=" + dom.byId("login").textContent + "&";
                                url += item.args.join("&");
                            }
                            url += ('New Window' == item.label) ? "&target='new'"
                                 : ('login.pl' == item.module)  ? "&target='_top'"
                                                                : "";
                            item.url = url;
                            kids.push(item);
                        });
                    }
                }
                onComplete(kids);
             },
            getRoot: function(onItem, onError){
                // get the root object, we will do a get() and callback the result
                this.store.get('0').then(onItem, onError);
            },
            getLabel: function(object){
                // just get the name (note some models makes use of 'labelAttr' as opposed to simply returning the key 'name')
                return object.label;
            }
        });

        var tree = new Tree({
            model: model,
            persist: false,
            autoExpand: false,
            showRoot: false,
            openOnClick: true,
            getIconClass: function(/*dojo.data.Item*/ item, /*Boolean*/ opened){
                return (!item || item.menu) ? (opened ? "dijitFolderOpened" : "dijitFolderClosed") : "dijitLeaf"
            },
            onClick: function(item){
                location.hash = item.url;
            }
        }, 'menuTree'); // make sure you have a target HTML element with this id
        tree.startup();
        var menu = new Menu({
            targetNodeIds: ['menuTree'],
        });
        return menu;
    }
 });
});
