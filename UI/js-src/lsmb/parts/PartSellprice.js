define([
    "dijit/form/ComboBox",
    "dijit/form/Textarea",
    "dijit/form/_AutoCompleterMixin",
    "dijit/form/_ComboBoxMenu",
    "dojo/_base/declare",
    "dojo/topic",
    "dojo/keys",
    "lsmb/parts/PartStore",
    "dojo/text!./templates/DropDownTextarea.html"
    ], function(
        ComboBox,
        Textarea,
        _AutoCompleterMixin,
        _ComboBoxMenu,
      declare,
        topic,
        keys,
        store
      ){
        return declare("lsmb/parts/PartsSellprice",[Textarea, _AutoCompleterMixin], {
            channel: null,
            height: null,
            store:  store,
            queryExpr: "*${0}*",
            style: "width: 15ex",
            autoComplete: false,
            highlightMatch: "all",
            searchAttr: "sellprice",
            labelAttr: "label",
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
            }, // startup
            _onKey: function(e) {
                if (e.keyCode !== keys.SPACE
                    && e.keyCode !== keys.ENTER) {
                    this.inherited(arguments);
                }
            } // _onKey
        });
    });
