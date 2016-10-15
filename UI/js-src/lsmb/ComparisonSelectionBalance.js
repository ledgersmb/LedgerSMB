define("lsmb/ComparisonSelectionBalance",
       ["dijit/layout/ContentPane",
        "dojo/_base/declare",
        "dojo/dom",
        "dojo/topic",
        "dojo/dom-style",
        "dijit/registry",
        "dojo/_base/array"
        ],
        function(ContentPane, declare, dom, topic, domStyle, registry, array) {
            return declare("lsmb/ComparisonSelectionBalance", ContentPane, {
                topic: "",
                type: "",
                comparisons: 0,
                container: "",
                _show: function(c) {
                    if ( c && dom.byId(c)) {
                        domStyle.set(c,"display","block");
                    }
                },
                _hide: function(c) {
                    if ( c && dom.byId(c)) {
                        domStyle.set(c,"display","none");
                    }
                },
                _interval: function(state) {
                    var _regid = registry.byId("interval");
                    _regid.set("required",state)
                          .set("disabled",!state);
                    if ( state ) {
                        _regid.focus();
                    }
                },
                _toggles: function(ids,l) {
                    for ( var i = 1 ; i <= 9 ; i++ ) {
                        var _cdDom = dom.byId(ids + "_" + i);
                        var state = ( i <= this.comparisons && l );
                        registry.byId("to_date_" + i).set("required",state);
                        registry.byId("to_date_" + i).set("disabled",!state);
                        ( state ? this._show : this._hide)(_cdDom);
                    }
                },
               _setTypeAttr: function (type) {
                    this.type = type;
                },
                _getTypeAttr: function (type) {
                    return this.type;
                },
                _setComparisonsAttr: function (comparisons) {
                    this.comparisons = comparisons;
                    this._toggles("comparison_dates",this.get("type")=="by_dates");
                },
                _getComparisonsAttr: function (comparisons) {
                    return this.comparisons;
                },
                update: function(targetValue) {
                    var _cDom = dom.byId(this.id);
                    if ( targetValue === "by_dates"   ) {
                        this.set("type",targetValue);
                        this._show(this.container);
                        this._hide("date_period_id");
                        this._toggles("comparison_dates",1);
                    } else if ( targetValue === "by_periods" ) {
                        this.set("type",targetValue);
                        this._hide(this.container);
                        this._show("date_period_id");
                        this._toggles("comparison_dates",0);
                    } else if ( targetValue >= 0 && targetValue <= 9 ) {
                        this.set("comparisons",targetValue);
                    }
                    this._interval(this.get("comparisons") >= 0 && this.get("type") == "by_periods");
                },
                postCreate: function() {
                    var self = this;
                    this.inherited(arguments);
                    this.container = this.id;

                    this.own(
                        topic.subscribe(self.topic,function(targetValue) {
                            self.update(targetValue);
                        })
                    );
                    /*
                     * A bit of evil here.
                     * We currently are not able to get default values from the report definition,
                     * and we need the dialog box to be set properly.
                     * The logic will read the comparison_type and comparison_periods and assign
                     * defaults values if they aren't already set.
                     * Note: consider setters & getters.
                     */
                    var _selectedRadio = array.filter(registry.findWidgets(dom.byId("comparison_type_radios")), function(radio){
                        return radio.get("checked");
                    }).pop();
                    if ( !_selectedRadio ) {
                        // Click the default button. This should be done elsewhere
                        // TODO: Move this to the proper place to avoid duplications is initial values. YL 2016-05-04
                        _selectedRadio = registry.byId("comparison_by_periods");
                    }
                    if ( _selectedRadio ) {
                        _selectedRadio.set("checked", true);
                        this.update(_selectedRadio.get("value"));      // Button should send message back
                    }
                    var _comparison_periods = registry.byId("comparison_periods");
                    this.update(_comparison_periods.get("value") || 0);      // Button should send message back
                }
            });
       });
