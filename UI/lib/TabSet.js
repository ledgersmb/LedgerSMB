define([
    'dijit/layout/TabContainer',
    'dojo/_base/declare'
    ],
    function(TabContainer, declare) {
      return declare('dijit/layout/TabContainer',
        [TabContainer],
        {
          startup: function(activeDiv, boxSize) {
           var myself = this; // needed for AMD query usage below.
           var active;
           require (['dojo/query', 
                     'dijit/layout/ContentPane', 
                     'dijit/registry', 'dojo/domReady!'],
           function(query, cp, registry) {
               query('div.lsmbtab').forEach(function(cnode){
               new cp (
                   { "data-dojo-type": 'dijit.layout.ContentPane',
                     "title": cnode.title},
                   cnode 
               );
               var t = registry.byId(cnode.id);
               if (t !== undefined){
                   myself.addChild(t);
                   t.startup();
               }
               });
               var ad = registry.byId(activeDiv);
               myself.selectChild(ad);
            });
            this.inherited(arguments);
            this.resize(boxSize);
          }
          
        });
    }
    );

