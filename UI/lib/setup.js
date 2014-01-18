/* construct_form_node(query, cls, registry,
 *                     textbox, checkbox, radio, select, button, textarea,
 *                     input)
 * This constructs the appropriate dojo/dijit object from the input provided and
 * returns it to the calling function.  query and cls are needed for select box
 * and textbox class detection.  input is the node.  The others are appropriate
 * dijit/dojo classes for the widgets.
 */
/*

/* Set up form.tabular forms.  
 * Supports the following additional classes for setting columns
 * cols-1
 * cols-2
 * cols-3
 *
 * Normally tabular will attach to the form element in most simple forms, but
 * for more complex ones, you can use div instead.
 *
 * Also sets up textboxes, checkboxes, and date pickers in the forms.
 *
 * As of first commit only setting up table containers.
 */
/*
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
              'dojo/domReady!'
             ],
      function(query, registry, cls, construct, table, textbox, checkbox, 
               radio, select, button, textarea, contentpane)
      {
             lsmbConfig.dateformat = lsmbConfig.dateformat.replace('m', 'M');
             var parse = false;
             query('body.dojo-declarative').forEach(function() { parse = true; });
             if (parse){
                 return require(['dojo/parser', 'dojo/domReady!'],
                        function(parser){
                            return parser.parse();
                        });
             }
             query('.tabular').forEach(
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
);*/

require(['lsmb/lib/Loader', 'dojo/cookie', 'dojo/domReady!'],
function(l){
    if (location.search.indexOf('&dojo=no') != -1) {
        dojo.cookie("lsmb-dojo-disable", "yes", {});
    } else if (location.search.indexOf('&dojo') != -1) {
        dojo.cookie("lsmb-dojo-disable", "no", {});
    }

    if (dojo.cookie("lsmb-dojo-disable") != 'yes') {
        loader = new l;
        loader.setup();
    } else {
        init();
    }
});
