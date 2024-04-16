/** @format */

define(["dojo/_base/declare", "dijit/form/Button"], function (declare, button) {
    return declare("lsmb/payments/JumpScreenButton", [button], {
        url: null,
        onClick: function () {
            window.__lsmbLoadLink(this.url);
        }
    });
});
