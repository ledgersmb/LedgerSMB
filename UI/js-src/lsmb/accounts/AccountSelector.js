/** @format */

define([
    "lsmb/FilteringSelect",
    "dojo/_base/declare",
    "lsmb/accounts/AccountRestStore"
], function (filteringSelect, declare, accountRestStore) {
    var mySelect = new declare(
        "lsmb/accounts/AccountSelector",
        [filteringSelect],
        {
            store: accountRestStore,
            style: "width: 300px",
            //          query: {"charttype": "A"},
            highlightMatch: "all",
            searchAttr: "label",
            labelAttr: "label",
            initialValue: null,
            constructor: function () {
                this.inherited(arguments);
                this.initialValue = arguments[0].value;
            }
        }
    );
    return mySelect;
});
