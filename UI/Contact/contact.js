require(['dojo/parser', 
         'dojo/query', 
         'dojo/dom', 
         "dijit/layout/TabContainer",
         "dijit/layout/ContentPane",
         'lsmb/Contact/tabs',
          'dijit/registry',
         'dojo/ready'],
       function(parser, query, dom, tc, cp, obj, registry){
           parser.instantiate([dom.byId('contact_tabs')], 
              { "data-dojo-type": "dijit/layout/TabContainer" }
           );
           var tabs = registry.byId('contact_tabs');
           query('.container').forEach(function(cnode){
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


require([
	'lsmb/Contact/tabs',
	'dojo/parser',
	'dojo/ready'], 
	function(
		  obj,
		  parser){
		}
);


