
define(['dijit/registry','dojo/ready'],
    function(registry, ready) {
      return {
        init: function(){
          // global should get set on the page, but is not available at init.
          // Need to wait for widgets to initialize before setting active tab.
          // dojo/ready queues this job to run after the parser is finished.
          if (activeDiv) {
            ready(function() {
              var td = registry.byId('contact_tabs');
              var ad = registry.byId(activeDiv);
              console.log(td,ad,activeDiv);
              td.selectChild(ad);

            });
          }
        }
      };
    }
    );
