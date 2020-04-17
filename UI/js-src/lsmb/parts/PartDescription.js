/** @format */

/* eslint no-template-curly-in-string:0 */

define([
   "dijit/form/TextBox",
   "dijit/_HasDropDown",
   "dijit/form/_AutoCompleterMixin",
   "dijit/form/_ComboBoxMenu",
   "dojo/_base/declare",
   "dojo/topic",
   "dojo/keys",
   "lsmb/parts/PartRestStore",
   "dojo/text!./templates/DropDownTextarea.html"
], function (
   textBox,
   _HasDropDown,
   _AutoCompleterMixin,
   _ComboBoxMenu,
   declare,
   topic,
   keys,
   partRestStore,
   dropDownTextarea
) {
   return declare(
      "lsmb/parts/PartDescription",
      [textBox, _HasDropDown, _AutoCompleterMixin],
      {
         channel: null,
         height: null,
         store: partRestStore,
         /* eslint no-template-curly-in-string:0 */
         queryExpr: "*${0}*",
         autoComplete: false,
         innerStyle: "",
         highlightMatch: "all",
         searchAttr: "description",
         labelAttr: "label",
         templateString: dropDownTextarea,
         dropDownClass: _ComboBoxMenu,
         autoSizing: true,
         startup: function () {
            var self = this;
            this.inherited(arguments);
            if (this.channel) {
               this.own(
                  topic.subscribe(this.channel, function (selected) {
                     self.set("value", selected[self.searchAttr]);
                  })
               );
               // eslint-disable-next-line no-unused-vars
               this.on("change", function (newValue) {
                  if (self.item) {
                     topic.publish(self.channel, self.item);
                  }
               });
            }
            this._autoSize();
         }, // startup
         _autoSize: function () {
            if (!this.autoSizing) {
               return;
            }
            // setting to 'auto' first helps to shrink
            // the height when possible.
            this.textbox.style.height = "1em";
            this.textbox.scrollTop = 0;
            this.textbox.style.height = this.textbox.scrollHeight + "px";
         }, // autoSize
         _onInput: function () {
            this.inherited(arguments);
            this._autoSize();
         }, // _onInput
         _onKey: function (e) {
            if (e.keyCode !== keys.SPACE && e.keyCode !== keys.ENTER) {
               this.inherited(arguments);
            }
            this._autoSize();
         }, // _onKey
         set: function () {
            this.inherited(arguments);
            this._autoSize();
         } // set
      }
   );
});
