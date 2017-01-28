define([
    "dijit/form/ComboBox",
    "dijit/form/CurrencyTextBox",
    "dijit/form/_AutoCompleterMixin",
    "dijit/form/_ComboBoxMenu",
    "dojo/_base/declare",
    "dojo/topic",
    "dojo/keys",
    "lsmb/parts/PartStore",
    "dojo/number",
    "dojo/text!./templates/DropDownTextarea.html"
    ], function(
        ComboBox,
        CurrencyTextBox,
        _AutoCompleterMixin,
        _ComboBoxMenu,
      declare,
        topic,
        keys,
        store,
        number
      ){
        return declare("lsmb/parts/PartsSellprice",[CurrencyTextBox, _AutoCompleterMixin], {
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
                                var s = selected[self.searchAttr];
                                s = number.parse(s, {locale: self.constraints.locale});
                                self.set("value",self.format( s, { currency: self.constraints.currency } ));
                            }));
                    this.on("change",
                            function(newValue) {
                                if ( newValue ) {
                                    var item = { sellprice: newValue };
                                    topic.publish(self.channel,item);
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
