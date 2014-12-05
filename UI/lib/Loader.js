/* lsmb/lib/Loader
 * A module for loading and setting up Dojo on LSMB screens.
 * 
 * This exposes two methods:
 *
 * setup() 
 *
 * sets up all widgets on a page
 *
 * createWidget(dnode) 
 *
 * creates a wedget from a DOM node.  Returns undef if the widget already 
 * exists. The choice to return undef allows one to check the return value 
 * of the function, and avoid calling if the widget already exists.
 */

define([
     // base
    'dojo/_base/declare',
    'dojo/date/locale',
    'dijit/registry',
    'dojo/parser',
    'dojo/query',
    'dojo/ready',
    'dijit/_WidgetBase',
    'dojo/dom-construct',
    // widgets
    // row1
    'lsmb/lib/TabularForm',
    'dijit/form/Textarea',
    'lsmb/lib/DateTextBox',
    'dijit/form/CheckBox',
    'dijit/form/RadioButton',
    'dijit/form/TextBox',
    //row2
    'dijit/form/Select',
    'dijit/form/Button',
    'dojo/dom-form',
    //more
    "dojo/request/xhr",
    'dojo/on'
    ],
function(
    // base
    declare, date_locale, registry, parser, query, ready, wbase, construct,
    // widgets
    tabular, textarea, datebox, checkbox, radio, textbox, 
    select, button, form, xhr, on) {
    return declare(wbase, {
        nodeMap: { // hierarchy nodeName->class, input type treated as class
                   // for INPUT elements, type beats class.
               DIV: {
               '__default': function(){ return undefined; },
                 'tabular': function(node){
                                        return new tabular({
                                              showLabels: true,
                                              customClass: 'lsmbtabular',
                                              orientation: 'horiz'
                                                     }, node);
                            }
             
                    },
                 A: { '__default': function(a) {
                           if (a.target || ! a.href){
                               return undefined; 
                           }
                           on(node, 'click', function(e){
                               e.preventDefault();
                               load_link(xhr, node.href);
                           });
                     }

                    }, 
              FORM: { '__default': function(formnode){
                                       console.log(formnode);
                                       on(formnode, 'submit', 
                                       function(e){ 
                                           console.log(formnode);
                                           var method = formnode.method;
                                           if (undefined == method){
                                               method = 'GET';
                                           }
                                           e.preventDefault();
                                           xhr(formnode.action, 
                                              {"handlesAs": "text",
                                                  "method": formnode.method,
                                                   "query": fquery,
                                              }).then(
                                              function(doc){
                                                   set_main_div(doc);
                                              });
                                      });
                                      return undefined;
                                   },
                       'dojoized': function(){ return undefined; },
                    },
          TEXTAREA: { '__default': function(input){
                                    return new textarea(
                                           { "name": input.name,
                                            "value": input.innerHTML,
                                            "title": input.title, 
                                             "cols": input.cols,
                                         "required": input.required,
                                             "rows": input.rows}, input);
                                   },
                      // skip editors for now --CT
                      'editor': function(input) { return true }, 
                    },
             INPUT: {   'hidden': function(){ return undefined},
                          'date': function(input){
                                                var style = {};
                                                if (input.size !== undefined 
                                                    && input.size !== '')
                                                {
                                                   style['width'] = 
                                                          (input.size * 0.7) 

                                                        + 'em';
                                                   }
                                                var val = input.value;
                                                if (val == ''){
                                                     val = undefined;
                                                } else if (/\d\d\d\d-\d\d-\d\d/.test(val)) {
                                                    // do nothing: the widget expects                                               
                                                    // iso8601 formatted input
                                                } else {
                                                    val = dojo.date.locale.parse( val, { datePattern: lsmbConfig.dateformat.replace(/mm/,'MM'), selector: "date" });
                                                }
                                                return new datebox({
                                                    "label": input.title,
                                                    "title": input.title,
                                                    "value": val,
                                                     "name": input.name,
                                                       "id": input.id,
                                                 "required": input.required,
                                                    "style": style,
                                                }, input);

                                  },
                      'checkbox': function(input){
                                        return new checkbox({
                                             "name": input.name,
                                            "value": input.value,
                                            "title": input.title,
                                         "required": input.required,
                                          "checked": input.checked
                                         }, input);
                                 },
                         'radio': function(input){
                                         return new radio({
                                             "name": input.name,
                                            "value": input.value,
                                            "title": input.title,
                                         "required": input.required,
                                          "checked": input.checked
                                        }, input);
                                 },
                      'password': function(input){
                                     if (undefined !== registry.byNode(input)){
                                        return undefined;
                                     }
                                     var style = {};
                                     if (input.size !== undefined 
                                        && input.size !== '')
                                     {
                                         style['width'] = (input.size * 0.6) 
                                                           + 'em';
                                     }
                                     return new textbox({
                                             "title": input.title,
                                             "label": input.title,
                                             "value": input.value,
                                              "name": input.name,
                                             "style": style,
                                          "required": input.required,
                                                "id": input.id,
                                              "type": 'password'
                                     
                                     }, input);
                                },
                    'AccountBox': function(input){
                                    // Since this requires db components, it
                                    // cannot be preloaded on every page.
                                    require(['lsmb/accounts/AccountSelector',
                                             'dojo/ready'],
                                    function(accountselector, ready){
                                      var value = input.value;
                                      ready(function(){
                                          return new accountselector({
                                              "name": input.name,
                                             "value": value,
                                          "required": input.required,
                                          }, input);
                                      });
                                      /**********
                                      ready(function(){
                                         var widget = registry.byId(input.id);
                                         widget.set('value', value); 
                                      });   
                                      ****************/ 
                                    });
                                 },
                     '__default': function(input){
                                     if (undefined !== registry.byNode(input)){
                                        return undefined;
                                     }
                                     var style = {};
                                     if (input.size !== undefined 
                                         && input.size !== '')
                                     {
                                         style['width'] = (input.size * 0.6) 
                                                           + 'em';
                                     }
                                     return new textbox({
                                         "title": input.title,
                                         "label": input.title,
                                         "value": input.value,
                                          "name": input.name,
                                         "style": style,
                                      "required": input.required,
                                            "id": input.id
                                     }, input);
                                  }
                    },
            SELECT: {  '__default': function(input){
                                      var optlist = [];
                                      query('option', input).forEach(
                                      function(opt){
                                          var entry = {
                                             "label": opt.innerHTML,
                                                "id": input.id,
                                             "value": opt.value
                                         };
                                         if (opt.selected){
                                             entry["selected"] = true;
                                         }
                                         optlist.push(entry);
                                      });
             
                                      return new select(
                                             { "name": input.name,
                                            "options": optlist,
                                              "title": input.title,
                                                 "id": input.id,
                                           "required": input.required,
                                            "on_load": input.on_load
                                             } , input); 
                                  }
                 },
          BUTTON: {
                    '__default': function(input){
                          return new button(
                              { "name": input.name,
                                "type": input.type,
                                  "id": input.id,
                               "title": input.innerHTML,
                               "value": input.value
                              }, input
                          );
                     }
                 }
        },
        constructor: function(){
        },
        // createWidget(domNode)
        //
        // Creates a widget from a domNode.  This is used in a number of cases,
        // including the main dynamic parser and the lsmb/lib/TabularForm
        // widget.
        //
        // Note that this *must* be called inside a ready() block, either by 
        // the parser.parse() or by setup().
        getInputSize: function(dnode) {
            return dnode.size * 0.6 + 'em';
        },
        createWidget: function(dnode) {
            if (undefined !== registry.byId(dnode.id)){
               return undefined;
            }
            if (undefined == this.nodeMap[dnode.nodeName]){
               return undefined;
            }
            if ('INPUT' == dnode.nodeName && 'file' == dnode.type){
               // otherwise renders as a text field.  We should change this
               // down the road.  --CT
               return undefined;
            }
            if ('INPUT' == dnode.nodeName){
                var classKey;
                classKey = dnode.type;
                if (undefined !== this.nodeMap.INPUT[classKey]){
                    return this.nodeMap.INPUT[classKey](dnode);
                }
            }
            var classes = dnode.className.split(' ');
            for (var i = 0; i <= classes.length; i++){
                classKey=classes[i];
                if (undefined !== this.nodeMap[dnode.nodeName][classKey]){
                    return this.nodeMap[dnode.nodeName][classKey](dnode);
                }
            }
            if (undefined !== this.nodeMap[dnode.nodeName].__default){
                return this.nodeMap[dnode.nodeName].__default(dnode);
            }
            return undefined;
        },
        setup: function(){
            var declarative = false;
            var myself = this;
            query('div.dojo-declarative').forEach(function(){
                 declarative = true;
            });
            if (declarative){
               return parser.parse(); 
            } 
            query('#maindiv .tabular label').forEach(function(dnode){
                 construct.destroy(dnode);
            });
            query('#maindiv *').forEach(function(dnode){
                ready(function(){
                   var onclick = dnode.onclick;
                   widget = myself.createWidget(dnode);
                   if (undefined !== widget){
                       ready(function(){
                           var wdgt_tmp=registry.byId(dnode.id);
                           //registry.byId(dnode.id).startup();
                           if(wdgt_tmp) wdgt_tmp.startup();//avoid TypeError: wdgt_tmp is undefined
                        });
                   }
                   if (null !== onclick){
                       //alert(onclick); 
                       ready(function(){on(dnode, 'click', onclick)});
                   }
                });
            });
        }
   }); 
});   
