define(["dojo/_base/declare",
         "dijit/_WidgetBase",
         "dijit/_TemplatedMixin",
         "dijit/_WidgetsInTemplateMixin",
         "dijit/_Container"
        ],
        function (declare, _WidgetBase, _TemplatedMixin,
                  _WidgetsInTemplateMixin, _Container) {
            return declare("lsmb/InvoiceLine",
                           [_WidgetBase, _Container], {
                            });
        });
