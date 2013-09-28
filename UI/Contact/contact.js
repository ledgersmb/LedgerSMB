require([
         'dojo/query', 
         'dojo/dom', 
         "lsmb/lib/TabSet",
          'dojo/window',
         'dojo/domReady!'],
       function(query, dom, tc, win){
           var tabs = new tc({}, dom.byId('contact_tabs'));
           tabs.startup(activeDiv, win.getBox());
       } 
 
);

