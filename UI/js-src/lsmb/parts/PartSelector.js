define([
    'dijit/form/FilteringSelect',
    'dojo/_base/declare',
    'dojo/aspect',
    'dojo/topic',
    'lsmb/parts/PartStore'
    ], function(
      Select,
        declare,
        aspect,
        topic,
        store
      ){
        var mySelect = new declare('lsmb/parts/PartSelector',[Select],{
            store:  store,
            queryExpr: "*${0}*",
            style: 'width: 15ex',
            highlightMatch: 'all',
            searchAttr: 'text',
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
              store.emitter.on("partstore_loadcomplete",function(){
                  mySelf.set('value',mySelf.initialValue);
           });
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
                    topic.publish('/invoice/part-select/'+self.linenum,
                                  self.item);
                });
            }
        });

        aspect.around(mySelect, '_announceOption', function(orig) {
            return function (node) {
                this.searchAttr = 'label';
                var r = orig.call(this, node);
                this.searchAttr = 'text';
                return r;
            }
        });
        return mySelect;
      });
