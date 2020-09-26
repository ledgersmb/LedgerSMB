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
    return declare("lsmb/reports/PeriodSelector", [_WidgetBase, _Container], {
        channel: "",
        startup: function () {
            var self = this;

            this.inherited(arguments);
            this._by_dates = registry.byId("comparison_by_dates");
            this._by_periods = registry.byId("comparison_by_periods");
            this.own(
                on(this._by_dates, "change", function (newvalue) {
                    if (newvalue) {
                        self._update_display();
                        topic.publish(
                            self.channel,
                            "changed-period-type",
                            "by-dates"
                        );
                    }
                })
            );
            this.own(
                on(this._by_periods, "change", function (newvalue) {
                    if (newvalue) {
                        self._update_display();
                        topic.publish(
                            self.channel,
                            "changed-period-type",
                            "by-periods"
                        );
                    }
                })
            );
            this._update_display();
        },
        _update_display: function () {
            domStyle.set(
                dom.byId("date_dates_id"),
                "display",
                this._by_dates.get("checked") ? "" : "none"
            );
            domStyle.set(
                dom.byId("date_period_id"),
                "display",
                this._by_periods.get("checked") ? "" : "none"
            );
        }
    });
});
