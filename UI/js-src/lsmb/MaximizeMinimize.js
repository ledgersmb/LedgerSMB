/** @format */

define([
   "dojo/_base/declare",
   "dojo/dom",
   "dojo/dom-style",
   "dojo/on",
   "dijit/_WidgetBase"
], function (declare, dom, domStyle, on, _WidgetBase) {
   return declare("lsmb/MaximizeMinimize", [_WidgetBase], {
      state: "min",
      stateData: {
         max: {
            nextState: "min",
            imgURL: "payments/img/up.gif",
            display: "block"
         },
         min: {
            nextState: "max",
            imgURL: "payments/img/down.gif",
            display: "none"
         }
      },
      mmNodeId: null,
      setState: function (state) {
         var nextStateData = this.stateData[state];
         this.domNode.src = nextStateData.imgURL;
         this.state = state;
         domStyle.set(
            dom.byId(this.mmNodeId),
            "display",
            nextStateData.display
         );
      },
      toggle: function () {
         this.setState(this.stateData[this.state].nextState);
      },
      postCreate: function () {
         var domNode = this.domNode;
         var self = this;
         this.inherited(arguments);

         this.own(
            on(domNode, "click", function () {
               self.toggle();
            })
         );
         this.setState(this.state);
      }
   });
});
