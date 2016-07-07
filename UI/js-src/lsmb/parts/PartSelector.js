define([
    'dijit/form/FilteringSelect',
    'dojo/_base/declare',
    'dojo/aspect',
    'dojo/topic',
    'dojo/when',
    'lsmb/parts/PartRestStore'
    ], function(
      Select,
        declare,
        aspect,
        topic,
        when,
        store
      ){
        var mySelect = new declare('lsmb/parts/PartSelector',[Select],{
            store:  store,
            queryExpr: "*${0}*",
            style: 'width: 15ex',
            highlightMatch: 'all',
            searchAttr: 'partnumber',
            labelAttr: 'label',
            autoComplete: false,
            initialValue:null,
            linenum: null,
          constructor:function(){
           this.inherited(arguments);
           this.initialValue=arguments[0].value;
          },
          postCreate:function(){
           var mySelf=this;
              this.inherited(arguments);
          },//postCreate
            startup:function(){
                var self = this;
                this.inherited(arguments);
                this.own(
                    topic.subscribe(
                        '/invoice/part-select/' + this.linenum,
                        function(selected) {
                            self.set('value',selected[self.searchAttr]);
                        }));
                this.on('change', function(newValue) {
                    when(self.store.get(newValue),function(value){
                        topic.publish('/invoice/part-select/'+self.linenum,
                                      value);
                    });
                });
            }
        });

        aspect.around(mySelect, '_announceOption', function(orig) {
            return function (node) {
                var savedSearchAttr = this.searchAttr;
                this.searchAttr = this.labelAttr;
                var r = orig.call(this, node);
                this.searchAttr = savedSearchAttr;
                return r;
            }
        });
        return mySelect;
      });
