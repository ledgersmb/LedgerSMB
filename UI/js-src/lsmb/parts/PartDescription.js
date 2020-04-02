define([
    "dijit/form/ComboBox",
    "dijit/form/TextBox",
    //    "dijit/form/ComboBoxMixin",
    "dijit/_HasDropDown",
    "dijit/form/_AutoCompleterMixin",
    "dijit/form/_ComboBoxMenu",
    "dojo/_base/declare",
    "dojo/topic",
    "dojo/keys",
    "lsmb/parts/PartRestStore",
    "dojo/text!./templates/DropDownTextarea.html"
    ], function(
        ComboBox,
        Textarea,
        //        ComboBoxMixin,
        _HasDropDown,
        _AutoCompleterMixin,
        _ComboBoxMenu,
      declare,
        topic,
        keys,
        store,
        template
      ){
        return declare("lsmb/parts/PartDescription",[Textarea, _HasDropDown, _AutoCompleterMixin], {
            channel: null,
            height: null,
            store:  store,
            queryExpr: "*${0}*",
            autoComplete: false,
            innerStyle: "",
            highlightMatch: "all",
            searchAttr: "description",
            labelAttr: "label",
            templateString: template,
            dropDownClass: _ComboBoxMenu,
            autoSizing: true,
            startup: function() {
                var self = this;
                this.inherited(arguments);
                if (this.channel) {
                    this.own(
                        topic.subscribe(
                            this.channel,
                            function(selected) {
                                self.set("value",selected[self.searchAttr]);
                            }));
                    this.on("change",
                            function(newValue) {
                                if (self.item) {
                                    topic.publish(self.channel, self.item);
                                }
                            });
                }
                this._autoSize();
            }, // startup
            _autoSize: function() {
                if (! this.autoSizing) return;
                // setting to 'auto' first helps to shrink
                // the height when possible.
                this.textbox.style.height = "1em";
                this.textbox.scrollTop = 0;
                this.textbox.style.height =
                    this.textbox.scrollHeight + "px";
            }, // autoSize
            _onInput: function() {
                this.inherited(arguments);
                this._autoSize();
            }, // _onInput
            _onKey: function(e) {
                if (e.keyCode !== keys.SPACE
                    && e.keyCode !== keys.ENTER) {
                    this.inherited(arguments);
                }
                this._autoSize();
            }, // _onKey
            set: function() {
                this.inherited(arguments);
                this._autoSize();
            } // set
        });
    });
