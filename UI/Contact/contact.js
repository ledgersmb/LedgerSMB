require([
         'dojo/query', 
         'dojo/dom', 
         "lsmb/lib/TabSet",
         "dijit/layout/ContentPane",
         'lsmb/Contact/tabs',
          'dijit/registry',
         'dojo/ready'],
       function(query, dom, tc, cp, obj, registry){
           var tabs = new tc({}, dom.byId('contact_tabs'));
           tabs.startup();
           obj.init();
       } 
 
);

