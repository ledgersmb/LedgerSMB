/** @format */

define(["dojo/_base/declare", "dijit/registry", "dijit/form/Button"], function (
    declare,
    registry,
    button
) {
    return declare("lsmb/payments/JumpScreenButton", [button], {
        url: null,
        onClick: function () {
            registry.byId("maindiv").load_link(this.url);
        }
    });
});
