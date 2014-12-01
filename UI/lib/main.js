function SwitchMenu(id) {
    var obj = id;
    if (document.getElementById) {
        var element = document.getElementById(obj);
		
        element = document.getElementById(obj);
        if (element.className == 'menu_open'){
            element.className = 'menu_closed';
        } else {
            element.className = 'menu_open';
        }
        return false;
    }		
}

function load_link(xhr, href) {
    xhr(href, {"handlesAs": "text"}).then(function(doc){
         set_main_div(doc);
    });
}

function set_main_div(doc){
        var body = doc.match(/<body[^>]*>([\s\S]*)<\/body>/i);
        var newbody = body[1];
        require(['dojo/query', 'dojo/dom-style', 'dijit/registry', 'dojo/domReady!'],
        function(query, style, registry){
           var mainCP = registry.byId('maindiv');
           mainCP.domNode.style.visibility = 'hidden';
           style.set(mainCP, 'visibility', 'hidden');
           mainCP.set('content', newbody);
           setup_dojo();
               mainCP.domNode.style.visibility = 'visible';
           require(['dojo/domReady!'], 
           function(){
           });
        });
}

function setup_dojo() {
   console.log('setting up dojo');
   require(     ['dojo/query', 
              'dijit/registry',
              'dojo/dom-class',
              'dojo/dom-construct',
              'dojox/layout/TableContainer',
              'dijit/form/TextBox',
              'dijit/form/CheckBox',
              'dijit/form/RadioButton',
              'dijit/form/Button',
              'dijit/layout/ContentPane',
              'dijit/form/Textarea',
             ],
      function(query, registry, cls, construct, table, textbox, checkbox, 
               radio, select, button, textarea, contentpane)
      {
             lsmbConfig.dateformat = lsmbConfig.dateformat.replace('m', 'M');
             var parse = false;
             query('div.dojo-declarative').forEach(function() { parse = true; });
             if (parse){
                 return require(['dojo/parser'],
                        function(parser){
                            return parser.parse();
                        });
             }
             query('#maindiv .tabular').forEach(
                  function(node){
                      var tabparams = {
                             'data-dojo-type': 'dojox/layout/TableContainer',
                             'showLabels': 'True',
                             'orientation': 'horiz',
                             'customClass': 'tabularform',
                             'cols': 1
                      };
                      var mycols;
                      if (cls.contains(node, 'col-1')){
                         tabparams['cols'] = 1;
                      } else if (cls.contains(node, 'col-2')){
                         tabparams['cols'] = 2;
                      } else if (cls.contains(node, 'col-3')){
                         tabparams['cols'] = 3;
                      } 
                      var mytabular = new table(tabparams, node);
                      // Must hide labels in such a form!
                      query('label', node).forEach(function(node2){
                         construct.destroy(node2);
                      });

                      var counter = 0;
                      // Process inputs
                      query('*', node).forEach(
                         function(input){
                             if (input.nodeName == 'DIV')
                             {
                                 if (cls.contains(input, 'input_line')){
                                    var nodes_to_add = counter % mycols;
                                    for (i=nodes_to_add; i<mycols; i++){
                                        mytabular.addChild(new contentpane({
                                           "content": ""
                                        })); // spacer
                                    }
                                    counter = 0;
                                 }
                             }
                             var widget = registry.byNode(input);
                             if (widget == undefined && input !== undefined){
 
                                 widget = construct_form_node(
                                               query, cls, registry, 
                                               textbox, checkbox, 
                                               radio, select,
                                               button, textarea, input
                                 );
                             }
                             if (widget !== undefined){
                                ++counter;
                                if (input.nodeName == 'BUTTON'){
                                    var mycp = new contentpane(
                                    { content: "" }
                                );
                                 
                                mytabular.addChild(mycp);
                                mycp.addChild(widget); // obscures label
                                     
                                } else {
                                     mytabular.addChild(widget);
                                } 
                                try_startup(widget);
            
                             }
                         }
                      ); 
                      mytabular.startup();
                  }
             );

             query('input, select, button, textarea').forEach(
                  function(node){
                      var val;
                      var ntype = node.nodeName;
                      if (registry.byId(node.id) !== undefined){
                          return undefined;
                      }
                      var widget = construct_form_node(
                                           query, cls, registry, textbox, checkbox, 
                                           radio, select,
                                           button, textarea, node
                      );
                      if (! try_startup(widget)){
                            console.log(widget,node);
                      } 
                      else {
                      }
                  });
      }
   );

}
require([
       'dojo/on', 'dojo/query', "dojo/request/xhr", 'dojo/domReady!'
   ], function (on, query, xhr) {
        query('.menu_closed').forEach(function(node){
             on(node, 'click', function(e){
                   e.preventDefault();
                   SwitchMenu(node.id);
                }
             );
        });
        query('#menudiv a').forEach(function(node){
             if (node.href){
                 on(node, 'click', function(e){
                           e.preventDefault();
                           load_link(xhr, node.href);
                     }
                 );
             }
        });   
    }
);
