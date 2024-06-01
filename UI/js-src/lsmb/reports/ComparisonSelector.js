/** @format */

define([
    "dojo/_base/declare",
    "dojo/on",
    "dojo/dom",
    "dojo/dom-style",
    "dojo/topic",
    "dijit/registry",
    "dijit/_WidgetBase",
    "dijit/_Container"
], function (
    declare,
    on,
    dom,
    domStyle,
    topic,
    registry,
    _WidgetBase,
    _Container
) {
    return declare(
        "lsmb/reports/ComparisonSelector",
        [_WidgetBase, _Container],
        {
            channel: "",
            mode: "by-dates",
            postCreate: function () {
                this.inherited(arguments);
                this.own(
                    topic.subscribe(this.channel, (action, value) => {
                        var display = "";

                        if (action === "changed-period-type") {
                            this.mode = value;

                            if (value === "by-dates") {
                                display = this._comparison_periods.get("value");
                            }
                        }
                        this._update_display(display);
                    })
                );
            },
            startup: function () {
                this.inherited(arguments);
                this._comparison_periods = registry.byId("comparison-periods");
                this.own(
                    on(this._comparison_periods, "change", () => {
                        this._update_display(
                            this._comparison_periods.get("value")
                        );
                    })
                );
                this._update_display("");
            },
            _update_display: function (count) {
                if (count === "" || this.mode === "by-periods") {
                    domStyle.set(
                        dom.byId("comparison_dates"),
                        "display",
                        "none"
                    );
                    return;
                }
                var _count = parseInt(count, 10);
                if (Number.isNaN(_count)) {
                    return;
                } // invalid input

                domStyle.set(dom.byId("comparison_dates"), "display", "");
                for (var i = 1; i <= 13; i++) {
                    domStyle.set(
                        dom.byId("comparison_dates_" + i),
                        "display",
                        i <= _count ? "" : "none"
                    );
                }
            }
        }
    );
});
