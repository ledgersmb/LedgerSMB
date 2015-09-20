/* lsmb/lib/Loader
 * A module for loading and setting up Dojo on LSMB screens.
 *
 */

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
								load_link(xhr, domattr.get(dnode,'href'));
                    });
					 }
				});
		  },
		  rewriteFormSubmissions: function(formnode){
				if (undefined == formnode.action){
					 return undefined;
				}
				// <button> tags get rewritten to <input type="submit" tags...
				query('input[type="submit"]', formnode).forEach(function(b) {
					 on(b, 'click', function(){
						  domattr.set(formnode, 'clicked-action',
										  domattr.get(b,'value'));
					 });
				});

				on(formnode, 'submit',
					function(evt){
						 var method = domattr.get(formnode,'method');
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
						 var options = { "handleAs": "text" };
						 if ('get' == method.toLowerCase()){
							  url = url + '?' + qobj;
						 } else {
							  options['method'] = method;
							  options['data'] = qobj;
						 }
						 load_form(xhr, url, options);
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
