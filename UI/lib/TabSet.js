/* lsmb/lib/TabSet
 * A Dojo tabset widget for LedgerSMB
 * based on dijit/layout/TabContainer
 *
 * This widget features autodetection of internal content panes but currently 
 * does not support nesting unless content panes are remote.  That may change
 * in future versions.  Additionally, this widget supports initial tab selection
 * and size declarations via the startup() call.
 *
 * Overridden methods:
 *
 * startup(activeDiv, boxSize)
 *
 * activeDiv is the element id of the pane to be activated on startup, and
 * boxSize is the size to make the tabset.
 *
 * Internal content panes are created from divs with a class of 'lsmb-tab' 
 * allowing for dojo-agnostic auto-detection.
 *
 * Sample (instantiates a tab set, sets the active div to the activeDiv 
 *         parameter in the global scope, and sets the size to the viewport):
 * require([
 *          'dojo/query',
 *          'dojo/dom',
 *          "lsmb/lib/TabSet",
 *          'dojo/window',
 *          'dojo/domReady!'],
 * function(query, dom, tc, win){
 *     var tabs = new tc({}, dom.byId('contact_tabs'));
 *     tabs.startup(activeDiv, win.getBox());
 * }
 * ); 
 *
 */
define([
    'dijit/layout/TabContainer',
    'dojo/_base/declare'
    ],
    function(TabContainer, declare) {
      return declare('dijit/layout/TabContainer',
        [TabContainer],
        {
          startup: function(activeDiv, boxSize) {
           var myself = this; // needed for AMD query usage below.
           var active;
           require (['dojo/query', 
                     'dijit/layout/ContentPane', 
                     'dijit/registry', 'dojo/domReady!'],
           function(query, cp, registry) {
               query('div.lsmbtab').forEach(function(cnode){
               new cp (
                   { "data-dojo-type": 'dijit.layout.ContentPane',
                     "title": cnode.title},
                   cnode 
               );
               var t = registry.byId(cnode.id);
               if (t !== undefined){
                   myself.addChild(t);
                   t.startup();
               }
               });
               var ad = registry.byId(activeDiv);
               myself.selectChild(ad);
            });
            this.inherited(arguments);
          }
          
        });
    }
    );

