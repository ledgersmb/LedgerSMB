define(["dojo/_base/declare",
    "dojo/store/JsonRest", "dojo/store/Observable",
//    "dojo/store/Memory", "dojo/store/Cache",
    "dijit/Tree", "dijit/tree/ObjectStoreModel",
    "dijit/tree/dndSource",
    "dijit/Menu", "dojo/dom", "dojo/domReady!"
], function(declare, JsonRest, Observable,
//    Memory, Cache,
    Tree, ObjectStoreModel,
    dndSource,
    Menu, dom
){
    // set up the store to get the tree data, plus define the method
    // to query the children of a node
    var restStore = new JsonRest({
        target:      "menu.pl?action=menuitems_json",
    });
    var store;
//    var memoryStore = new Memory();
//    store = new Cache(restStore, memoryStore);
    // give store Observable interface so Tree can track updates
    store = new Observable(restStore);

    // create model to interface Tree to store
    var model = new ObjectStoreModel({
        store: store,
        // query to get root node
        query: {id: '0'},
        // Utility routines
        mayHaveChildren: function(object){
            // if true, we might be missing the data, false and nothing should be done
            return "children" in object;
        },
        getChildren: function(object, onComplete, onError){
            // this.get calls 'mayHaveChildren' and if this returns true, it will load whats needed, overwriting the 'true' into '{ item }'
            this.store.query({parent_id: object.id}).then(function(fullObject){
                // copy to the original object so it has the children array as well.
                object.children = fullObject;
                // now that full object, we should have an array of children
                onComplete(fullObject);
            }, function(error){
                // an error occurred, log it, and indicate no children
                console.error(error);
                onComplete([]);
            });
        },
        getRoot: function(onItem, onError){
            // get the root object, we will do a get() and callback the result
            this.store.query({id: '0'}).then(onItem, onError);
        },
        getLabel: function(object){
            // just get the name (note some models makes use of 'labelAttr' as opposed to simply returning the key 'name')
            return object.label;
        }
    });

    // Custom TreeNode class (based on dijit.TreeNode) that allows rich text labels
    var MyTreeNode = declare(Tree._TreeNode, {
        _setLabelAttr: {node: "labelNode", type: "innerHTML"}
    });

    var tree = new Tree({
        model: model,
        dndController: dndSource,
        showRoot: false,
        openOnClick: true,
        _createTreeNode: function(args){
           return new MyTreeNode(args);
        },
        onClick: function(item){
            // Get the URL from the item, and navigate to it
            var url = "";
            if ( item.module ) {
                url += item.module + "?login=" + dom.byId("login").textContent + "&amp;";
                for ( var i = 0 ; i < item.args.length ; i++ ) {
                    url += item.args[i] + "&amp;";
                }
                if ( item.menu ) {
                    url += "id=" + item.id + "&amp;open=" + dom.byId("open").textContent;
                }
            }
//            if (item.module && (item.module != 'menu.pl') && ('login.pl' != item.module)) {
//            } else
            url += ('New Window' == item.label) ? "target = 'new'"
                 : ('login.pl' == item.module)  ? "target = '_top'"
                 : "";
            url += 'id="a_' + item.id + '"';
            url += 'class="'
                 + (item.label == 'New Window') ? 'menu-new-window'
                 : item.module                  ? 'menu-terminus'
                 :                                't-submenu'
                 + '"' + item.label + "</a>";   // text(item.label)
            location.href = url;
//            if ( item.module ) {
//            }
        }
    }, 'menuTree'); // make sure you have a target HTML element with this id
    console.dir(tree);

    var menu = new Menu({
        targetNodeIds: ['menuTree'],
        selector: ".dijitTreeNode"
    });
    console.dir(menu);
    return menu;
});
