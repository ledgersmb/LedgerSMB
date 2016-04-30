define("lsmb/ComparisonSelection",
       ["dijit/layout/ContentPane",
        "dojo/_base/declare",
        "dojo/dom",
        "dojo/topic",
        "dojo/dom-style"
        ],
        function(ContentPane, declare, dom, topic, domStyle) {
            return declare('lsmb/ComparisonSelection', ContentPane, {
                topic: "",
                id: "",
                show: function(c) {
                    if ( c ) domStyle.set(c,'display','block');
                },
                hide: function(c) {
                    if ( c ) domStyle.set(c,'display','none');
                },
                update: function(targetValue) {
                    var _cDom = dom.byId(this.id);
                    if ( targetValue == 'by_dates'   ) {
                        this.show(_cDom);
                    } else if ( targetValue == 'by_periods' ) {
                        this.hide(_cDom);
                    }
                },
                postCreate: function() {
                    var self = this;
                    this.inherited(arguments);

                    if ( this.container ) {
                        this.id = this.container;
                    }
                    if ( this.topic ) {
                        this.own(
                            topic.subscribe(self.topic,function(targetValue) {
                                self.update(targetValue);
                            })
                        );
                    }
                }
            });
       });
