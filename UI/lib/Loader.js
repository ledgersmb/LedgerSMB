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

function set_main_div(doc){
    console.log('setting body');
    var body = doc.match(/<body[^>]*>([\s\S]*)<\/body>/i);
    var newbody = body[1];
    require(['dojo/query', 'dojo/dom', 'dojo/dom-style',
	     'dijit/registry', 'dojo/domReady!'],
            function(query, dom, style, registry){
		var mainCP = registry.byId('maindiv');
		mainCP.destroyDescendants();
		style.set(mainCP, 'visibility', 'hidden');
		mainCP.set('content', newbody);
		setup_dojo();
		style.set(mainCP, 'visibility', 'visible');
		require(['dojo/domReady!'], function(){
		});
            });
}

define([
     // base
    'dojo/_base/declare',
    'dijit/registry',
    'dojo/query',
    'dojo/ready',
    'dijit/_WidgetBase',
    'dojo/dom-construct',
    'dojo/dom-form',
    'dojo/dom-attr',
    "dojo/request/xhr",
    'dojo/on'
    ],
function(
    // base
    declare, registry, query, ready, wbase, construct,
    domform, domattr, xhr, on) {
    return declare(wbase, {
        constructor: function(){
        },
	redirectMainATags: function(){
            query('#maindiv a').forEach(function(dnode){
		if (! dnode.target && dnode.href) {
                    on(dnode, 'click', function(e){
			e.preventDefault();
			load_link(xhr, dnode.href);
                    });
		}
	    });
	},
	rewriteFormSubmissions: function(formnode){ 
            if (undefined == formnode.action){
                return undefined;
            }

	    query('button', formnode).forEach(function(b){
		on(b, 'click', function(){
		    domattr.set(formnode, 'clicked-action',
				domattr.get(b,'value'));
		});
	    });

            on(formnode, 'submit', 
               function(evt){ 
                   var method = formnode.method;
                   evt.preventDefault();
                   var qobj = domform.toQuery(formnode);
                   qobj = 'action=' 
                       + domattr.get(formnode, 'clicked-action')
		       + '&' + qobj;
                   if (undefined == method){
                       method = 'GET';
                   }
                   var url = domattr.get(formnode, 'action');
                   console.log(url);
                   if ('GET' == method || 'get' == method){
                       url = url + '?' + qobj;
                       console.log(url);
                       xhr(url,
                           {"handleAs": "text",
                           }).then(
                               function(doc){
                                   set_main_div(doc);
                               });    
                   } else {
                       xhr(url,
                           {"handleAs": "text",
                            method: method,
                            data: qobj,
                           }).then(
                               function(doc){
                                   set_main_div(doc);
                               });
                   }
               });
         },
	rewriteAllFormSubmissions: function() {
	    myself = this;
	    query('#maindiv form:not(.dojoized)')
		.forEach(myself.rewriteFormSubmissions);
	},
        setup: function(){
            var myself = this;
	    
	    ready(function(){
		myself.redirectMainATags();
		myself.rewriteAllFormSubmissions();
	    });
        }
   }); 
});   
