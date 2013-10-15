require([
         'dojo/query',
         'dojo/dom',
         "lsmb/lib/TabSet",
          'dojo/window',
         'dojo/domReady!'],
       function(query, dom, tc, win){
           if (activeDiv != 'H') {
               activeDiv = 'A';
           }
           console.log(activeDiv);
           var tabs = new tc({doLayout: false}, dom.byId('account-tabs'));
           tabs.startup(activeDiv, win.getBox());
       }

);

