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
   "dijit/registry"
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
   registry
) {
   // set up the store to get the tree data, plus define the method
   // to query the children of a node
   var restStore = new JsonRest({
      target: "erp/api/v0/menu-nodes/",
      idProperty: "id"
   });
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
      // eslint-disable-next-line no-unused-vars
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

            var mainDiv = registry.byId("maindiv");
            mainDiv.load_link(url);
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
