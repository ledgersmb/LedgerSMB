define([
    "dijit/form/FilteringSelect",
    "dojo/_base/declare",
    "dojo/keys",
    "dojo/on",
    "dojo/hash",
    "dojo/dom-attr",
    "dojo/dom-form",
    "dojo/query",
    "dijit/registry"
    ],
       function(FilteringSelect, declare, keys, on, hash, domattr, domform,
                query, registry) {
           var c = 0;
           return declare("lsmb/FilteringSelect",
                          [FilteringSelect],
              {
                  onKey:function(e){

                      var d = this.dropDown;
                      if (d && e.keyCode === keys.TAB) {
                          this.onChange(d.getHighlightedOption());
                      }
                      return this.inherited(arguments);
                  }
              });
       }
    );
