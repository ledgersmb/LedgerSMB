
/* Note, this is the first code being executed. If we don't required
   the parser here, the "onLoad" parse event isn't going to fire. */
require(['lsmb/lib/Loader', 'dojo/cookie', 'dojo/parser',
	 'dojo/domReady!'],
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


function SwitchMenu(id) {
    var obj = id.replace(/^a/, 'menu');
//    console.log(id);
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

function set_main_div(doc){
//    console.log('setting body');
    var body = doc.match(/<body[^>]*>([\s\S]*)<\/body>/i);
    var newbody = body[1];
    require(['dojo/query', 'dojo/dom', 'dojo/dom-style',
	     'dijit/registry', 'dojo/domReady!'],
            function(query, dom, style, registry){
		var mainCP = registry.byId('maindiv');
		style.set(mainCP, 'visibility', 'hidden');
		mainCP.destroyDescendants();
		mainCP.set('content', newbody);
		setup_dojo();
		style.set(mainCP, 'visibility', 'visible');
		require(['dojo/domReady!'], function(){
		});
            });
}

var last_page;
function load_form(xhr, url, options) {
    if (url == last_page) {
        return;
    }
    last_page = url;
	 xhr(url, options).then(
		  function(doc){
				set_main_div(doc);
		  },
		  function(err){
				require(['dijit/registry'],function(registry){
					 var d = registry.byId('errorDialog');
					 if (0 == err.response.status) {
						  d.set('content','Low level networking problem');
					 } else {
						  d.set('content',err.response.data);
					 }
					 d.show();
				});
		  });
}

function load_link(xhr, href) {
    require(['dojo/hash'],
            function (hash) {
                hash(href);
	             load_form(xhr,href,{"handlesAs": "text"});
            });
}

function setup_dojo() {
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
}

require([
    'dojo/on', 'dojo/query',
    'dojo/dom-attr', 'dojo/topic',
    'dojo/request/xhr', 'dojo/ready', 'dojo/domReady!'
], function (on, query, domattr, topic, xhr, ready) {
    query('a.t-submenu').forEach(function(node){
        on(node, 'click', function(e){
            e.preventDefault();
            SwitchMenu(node.id.replace(/a/, 'menu'));
        }
          );
    });
    query('a.menu-terminus').forEach(function(node){
        if (node.href.search(/pl/)){
            on(node, 'click', function(e){
                e.preventDefault();
                load_link(xhr, domattr.get(node,'href'));
            });
        }
    });
    ready(function() {
        if (window.location.hash) {
            load_link(xhr, window.location.hash.substring(1));
        }
    });
    topic.subscribe("/dojo/hashchange", function(hash) {
//            console.log(hash);
        load_link(xhr, hash);
    });
});

