require([
         'dojo/query', 
         'dojo/dom', 
         "dijit/layout/TabContainer",
         "dijit/layout/ContentPane",
         'lsmb/Contact/tabs',
          'dijit/registry',
         'dojo/ready'],
       function(query, dom, tc, cp, obj, registry){
           var tabs = new tc({}, dom.byId('contact_tabs'));
           query('div.lsmbtab').forEach(function(cnode){
               new cp (
                   { "data-dojo-type": 'dijit.layout.ContentPane',
                     "title": cnode.title},
                   cnode 
               );
               var t = registry.byId(cnode.id);
               if (t !== undefined){
                   tabs.addChild(t);
               }
           });
           tabs.startup();
           obj.init();
       } 
 
);

