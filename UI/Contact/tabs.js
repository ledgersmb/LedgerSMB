define(['dijit/layout/TabContainer', 'dijit/layout/ContentPane', 'dojo/parser'],
    function(TabContainer, ContentPane, Parser) {
      return {
        init: function(){
          Parser.parse();
        }
      };
    }
    );
