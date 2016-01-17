
require(['dojo/parser', 'dojo/query', 'dojo/request/xhr', 'dojo/on',
         'dojo/domReady!'],
        function(parser, query, xhr, on) {
            parser.parse().then(function() {
                // delay the option of triggering load_link() until
                // the parser has run: before then, the maindiv widget
                // doesn't exist!
                query('a.menu-terminus').forEach(function(node){
                    if (node.href.search(/pl/)){
                        on(node, 'click', function(e){
                            e.preventDefault();
                            load_link(xhr, node.href);
                        });
                    }
                });

                if (window.location.hash) {
                    load_link(xhr, window.location.hash.substring(1));
                }
            });
        });


function fade_main_div() {
    // mention we're processing the request
    require(['dijit/registry', 'dojo/dom-style'],
            function(registry, style) {
                var mainCP = registry.byId('maindiv');
                style.set(mainCP.domNode, 'opacity', "30%");
            });
}

function hide_main_div() {
    require(['dijit/registry', 'dojo/dom-style'],
            function(registry, style) {
                var mainCP = registry.byId('maindiv');
                style.set(mainCP.domNode, 'visibility', 'hidden');
            });
}

function show_main_div() {
    require(['dijit/registry', 'dojo/dom-style'],
            function(registry, style) {
                var mainCP = registry.byId('maindiv');
                style.set(mainCP.domNode, 'visibility', 'visible');
            });
}



function set_main_div(doc){
    var body = doc.match(/<body[^>]*>([\s\S]*)<\/body>/i);
    var newbody = body[1];
    require(['dojo/query', 'dojo/dom', 'dojo/dom-style', 'dijit/registry',
             'dojo/on', 'dojo/_base/event', 'dojo/request/xhr'],
            function(query, dom, style, registry, on, event, xhr){
		          var mainCP = registry.byId('maindiv');
		          mainCP.destroyDescendants();
		          mainCP.set('content', newbody).then(
                    function() {
                        query('a', dom.byId('maindiv'))
                              .forEach(function (dnode) {
					                   if (! dnode.target && dnode.href) {
                                      on(dnode, 'click', function(e) {
								                  event.stop(e);
								                  load_link(xhr, dnode.href);
                                        });
                                  }
					               });

		                  show_main_div();
                    });
            });
}

function load_form(xhr, url, options) {
    fade_main_div();
	 xhr(url, options).then(
		  function(doc){
            hide_main_div();
				set_main_div(doc);
		  },
		  function(err){
            show_main_div();
				require(['dijit/registry'],function(registry){
					 var d = registry.byId('errorDialog');
					 if (0 == err.response.status) {
						  d.set('content','Could not connect to server');
					 } else {
						  d.set('content',err.response.data);
					 }
					 d.show();
				});
		  });
}

var last_page;
function load_link(xhr, href) {
    if (last_page == href) {
        return;
    }
    fade_main_div();
    require(['dojo/hash'],
            function (hash) {
                     hash(href);
                     last_page = href;
	             load_form(xhr,href,{"handlesAs": "text"});
            });
}

require([
    'dojo/on', 'dojo/query',
    'dojo/dom-class', 'dojo/topic',
    'dojo/request/xhr', 'dojo/domReady!'],
        function (on, query, domclass, topic, xhr) {
            query('a.t-submenu').forEach(function(node){
                on(node, 'click', function(e) {
                    e.preventDefault();
                    var parent = node.parentNode;
                    if (domclass.contains(parent, 'menu_closed')) {
                        domclass.replace(parent, 'menu_open', 'menu_closed');
                    }
                    else {
                        domclass.replace(parent, 'menu_closed', 'menu_open');
                    };
                });
            });
            topic.subscribe("/dojo/hashchange", function(hash) {
                load_link(xhr, hash);
            });
        });
