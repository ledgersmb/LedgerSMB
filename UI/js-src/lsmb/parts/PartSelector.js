/** @format */

/* eslint no-template-curly-in-string:0 */

define([
    "lsmb/FilteringSelect",
    "dojo/_base/declare",
    "dojo/aspect",
    "dojo/topic",
    "lsmb/parts/PartRestStore"
], function (filteringSelect, declare, aspect, topic, partRestStore) {
    var mySelect = new declare("lsmb/parts/PartSelector", [filteringSelect], {
        store: partRestStore,
        queryExpr: "*${0}*",
        style: "width: 15ex",
        highlightMatch: "all",
        searchAttr: "partnumber",
        labelAttr: "label",
        autoComplete: false,
        initialValue: null,
        channel: null,
        constructor: function () {
            this.inherited(arguments);
            this.initialValue = arguments[0].value;
        },
        startup: function () {
            this.inherited(arguments);
            if (this.channel) {
                this.own(
                    topic.subscribe(this.channel, (selected) => {
                        this.set("value", selected[this.searchAttr]);
                    })
                );
                this.on("change", () => {
                    topic.publish(this.channel, this.item);
                });
            }
        }
    });

    aspect.around(mySelect, "_announceOption", function (orig) {
        return function (node) {
            var savedSearchAttr = this.searchAttr;
            this.searchAttr = this.labelAttr;
            var r = orig.call(this, node);
            this.searchAttr = savedSearchAttr;
            return r;
        };
    });
    return mySelect;
});
