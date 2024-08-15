/** @format */
/* globals dijit */

define([
    "dojo/_base/declare",
    "dojo/on",
    "dojo/_base/lang",
    "dojo/_base/event",
    "dojo/mouse",
    "dojo/store/JsonRest",
    "dojo/store/Observable",
    "dojo/store/Memory",
    "dijit/Tree",
    "dijit/tree/ObjectStoreModel",
    "dojo/topic"
], function (
    declare,
    on,
    lang,
    event,
    mouse,
    JsonRest,
    Observable,
    Memory,
    Tree,
    ObjectStoreModel,
    topic
) {
    // set up the store to get the tree data, plus define the method
    // to query the children of a node
    var restStore = new Observable(
        new JsonRest({
            target: "erp/api/v0/menu-nodes",
            idProperty: "id"
        })
    );
    var memoryStore = new Memory({ idProperty: "id" });
    memoryStore = new Observable(memoryStore);

    var complete = false;
    // create model to interface Tree to store
    var model = new ObjectStoreModel({
        store: memoryStore,
        labelAttr: "label",
        mayHaveChildren: function (item) {
            return item.menu;
        },
        getChildren: function (object, onComplete, onError) {
            if (complete) {
                onComplete(memoryStore.query({ parent: object.id }));
            } else {
                restStore.query({}).then(
                    function (items) {
                        memoryStore.setData(items);
                        onComplete(memoryStore.query({ parent: object.id }));
                    },
                    function () {
                        onError();
                    }
                );
                complete = true;
            }
        },
        getRoot: function (onItem, onError) {
            onItem({ id: 0 });
        }
    });

    return declare("lsmb/menus/Tree", [Tree], {
        model: model,
        showRoot: false,
        openOnClick: true,
        postCreate: function () {
            this.inherited(arguments);

            this.own(
                on(
                    this.containerNode,
                    "mousedown",
                    lang.hitch(this, this.__onClick)
                )
            );
        },
        refresh: function () {
            // Destruct the references to any selected nodes so that
            // the refreshed tree will not attempt to unselect destructed nodes
            // when a new selection is made.
            // These references are contained in Tree.selectedItem,
            // Tree.selectedItems, Tree.selectedNode, and Tree.selectedNodes.
            this.dndController.selectNone();

            this.model.store.clearOnClose = true;

            // Completely delete every node from the dijit.Tree
            this._itemNodesMap = {};
            this.rootNode.state = "UNCHECKED";

            // Destroy the widget
            this.rootNode.destroyRecursive();

            // Recreate the model, (with the model again)
            complete = false;
            this.model.constructor(dijit.byId(this.id).model);

            // Rebuild the tree
            this.postMixInProperties();
            this._load();
        },
        startup: function () {
            this.inherited(arguments);
            var _this = this;
            /* eslint no-unused-vars:0 */
            topic.subscribe("lsmb/menus/Tree/refresh", function (message) {
                _this.refresh();
            });
        },
        onClick: function (item, node, _event) {
            // regular handling of non-leafs
            if (item.menu) {
                return;
            }

            // for leafs, either open in the current application,
            // or open a new window, depending on the trigger.
            var url = item.url;
            var newWindow =
                (mouse.isLeft(_event) && (_event.ctrlKey || _event.metaKey)) ||
                mouse.isMiddle(_event) ||
                item.standalone;
            if (newWindow) {
                /* eslint no-restricted-globals: 0 */
                // Simulate a target="_blank" attribute on an A tag
                window.open(
                    location.origin +
                        location.pathname +
                        location.search +
                        (url ? "#" + url : ""),
                    "_blank",
                    "noopener,noreferrer"
                );
            } else {
                // Add timestamp to url so that it is unique.
                // A workaround for the blocking of multiple multiple clicks
                // for the same url (see the MainContentPane.js load_link
                // function).
                url += "#" + Date.now();

                if (window.__lsmbLoadLink) {
                    if (url.charAt(0) !== "/") {
                        url = "/" + url;
                    }
                    window.__lsmbLoadLink(url);
                }
            }
        },
        __onClick: function (e) {
            // simulate "click opening in background tab"
            // (Ctrl+LeftMouse or MiddleMouse)
            if (mouse.isLeft(e) && !(e.ctrlKey || e.metaKey)) {
                return;
            }

            event.stop(e);
            e.preventDefault();

            var node = dijit.getEnclosingWidget(e.target);
            var item = node.item;
            this.onClick(item, node, e);
        }
    });
});
