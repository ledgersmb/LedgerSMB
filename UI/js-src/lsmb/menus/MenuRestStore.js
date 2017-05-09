define(["dojo/_base/declare",
    "dojo/store/JsonRest", "dojo/store/Observable",
    "dojo/store/Memory", "lsmb/menus/Cache",
    "dijit/Tree", "dijit/tree/ObjectStoreModel",
    "dijit/tree/dndSource",
    "dijit/Menu", "dijit/MenuSeparator", "dijit/PopupMenuItem",
    "dojo/when", "dojo/dom", "dojo/ready"
], function(declare, JsonRest, Observable,
    Memory, lsmbStoreCache,
    Tree, ObjectStoreModel,
    dndSource,
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
        var store = new lsmbStoreCache(restStore, memoryStore);
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
                var kids;
                if ( object.children ) {
                    kids = [];
                    for ( var i = 0 ; i < object.children.length ; i++ ) {
                        when(this.store.get(object.children[i]), function(o) {
                            kids.push(o);
                        });
                    }
                }
                onComplete(kids);
//                return kids;
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

        // Custom TreeNode class (based on dijit.TreeNode) that allows rich text labels
        var MyTreeNode = declare(Tree._TreeNode, {
            _setLabelAttr: {node: "labelNode", type: "innerHTML"}
        });
        var tree = new Tree({
            model: model,
            showRoot: false,
            openOnClick: true,
            _createTreeNode: function(args){
               return new MyTreeNode(args);
            },
            getIconClass: function(/*dojo.data.Item*/ item, /*Boolean*/ opened){
                return "";
                return (!item || this.model.mayHaveChildren(item) && item.menu) ? (opened ? "dijitFolderOpened" : "dijitFolderClosed") : "" //"dijitLeaf"
            },
            onClick: function(item){
                // https://demo.cloud.efficito.com/erp/1.5/login.pl?action=login&company=demo15#
                // ar.pl?login=demo_en&action=add&module=ar.pl&type=credit_note&#s3
                // ar.pl?login=ylavoie&action=add&module=ar.pl&type=credit_note&id="a_194"menu-new-window"
                // Get the URL from the item, and navigate to it
                var url = "/";
                if ( item.module ) {
                    url += item.module + "?login=" + dom.byId("login").textContent + "&";
                    for ( var i = 0 ; i < item.args.length ; i++ ) {
                        url += item.args[i] + "&";
                    }
                }
                if ( !item.module || item.module == 'menu.pl' || 'login.pl' == item.module) {
                    url += ('New Window' == item.label) ? "target = 'new'"
                         : ('login.pl' == item.module)  ? "target = '_top'"
                         : "";
                }
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
        tree.startup();
        var menu = new Menu({
            targetNodeIds: ['menuTree'],
            selector: "rowNode",
        });
        return menu;
    }
 });
});
