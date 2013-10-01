/* lsmb/lib/TabularForm
 * A tabular-form widget for LedgerSMB with some additional features
 * (loosely) inspired by Twitter Bootstrap(TM).
 *
 * Based on dojox/layout/TableContainer
 *
 * This widget is intended to be a generalized tabular data entry form layout
 * system.
 *
 * NODE CLASSES
 *
 * TabularForm supports a number of classes to help manage layouts for different
 * screen sizes.  While this is somewhat inspired by Twitter Bootstrap(TM), the
 * properties assign to the table instead of the grid column.  In other words
 * because this is for data entry forms, we simply manage the form as a whole 
 * and resize accordingly.  This is important because we typically want to 
 * preserve the logical structure of the form when we resize.
 *
 * For columns, we support the following classes.  Each is the number of 
 * columns of inputs supported, so would typically be double (i.e. col-1 is 
 * one column of inputs plus one column of labels).
 *
 * col-1
 * col-2
 * col-3
 * col-4
 * ..
 * col-n
 *
 * cols can also be passed in via the constructor.
 *
 * For resizing support we support the following:
 *
 * vertsize-mobile
 * vertsize-small
 * vertsize-med
 *
 * and 
 *
 * vertlabel-mobile
 * vertlabel-small
 * vertlabel-med
 *
 * mobile = width <= 480px wide
 * small = width 480-768 px wide
 * med = width 768-992px wide
 *
 * This allows you to control whether labels appear vertically or horizontally
 * based on column size, label size, and screen width.
 *
 *
 * Note that for nested TabularForm components, they are resized independently.
 *
 * LAYOUT RULES
 * 
 * 1.  class input_row contains a group of inputs which are rendered together 
 * on one or more rows.  Rows are terminated after an input-row completes.
 * 2.  buttons are contained inside a content pane to suppress labels.
 *
 */

define([
    'dojox/layout/TableContainer',
    'dojo/dom',
    'dojo/dom-class',
    'dijit/registry',
    'dijit/layout/ContentPane',
    'dojo/query',
    'dojo/window',
    'dojo/_base/declare'
    ],
    function(TableContainer, dom, cls, registry, cp, query, win, 
             declare) 
    {
      return declare('lsmb/lib/TabularForm',
        [TableContainer],
        {
        vertsize: 'mobile',
        vertlabelsize: '',
        constructor: function (mixIn, domNode){
            if (domNode !== undefined){
                // Number of columns
                var class_str = " " + domNode.className + " ";
                var classes = class_str.match(/ col-\d+ /);
                if (classes){ 
                    this.cols = classes[0].replace(/ col-(\d+) /, "$1");
                }

                //resize to one column on a size of....
                classes = class_str.match('/ virtsize-\w+ /');
                if (classes){
                    this.vertsize = classes[0].replace(/ virtsize-(\w+) /, "$1");               }

                //labels go vertical on a size of.....
                classes = class_str.match('/ virtlabel-\w+ /');
                if (classes){
                    this.vertlabelsize = 
                            classes[0].replace(/ virtlabel-(\w+) /, "$1");
                }
            }
        },
        postCreate: function(){
            this.inherited(arguments);
            var myself = this;
            query('*', this.domNode).forEach(function(dnode){
                                            myself.TFRenderElement(dnode)
            }); 
        },
        TFRenderElement: function(dnode){
           var myself = this;
           require(['lsmb/lib/Loader', 'dojo/ready'],
           function(l, ready){
            ready(function(){
              if (registry.byId(dnode.id)){
                 widget = registry.byId(dnode.id);
                 myself.addChild(widget);
                 widget.startup();
                 return;
              }
              loader = new l;
              if (cls.contains(dnode, 'input-row')){
                 TFRenderRow(dnode);
              }
              else {
                 var widget = loader.createWidget(dnode);
                 if (undefined !== widget) {
                    widget.startup();
                    myself.addChild(widget);
                 }
              }
            });
           });
        },
        TFRenderRow: function (dnode){
           var counter = 0;
           query('*', dnode).forEach(function(dnode){
               TFRenderElement(dnode);
               ++counter;
           });
           counter = counter % this.cols;
           for (i = counter; i < this.cols; ++i){
               var spc = new cp({content: '&nbsp;'});
               this.addChild(spc); 
           }
        },
        resize: function(){
           //TODO:  this needs to detect container size and restructure
           //accordingly. --CT
        }
        });
     });

