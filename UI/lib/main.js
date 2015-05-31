function SwitchMenu(id) {
    var obj = id.replace(/^a/, 'menu');
    console.log(id);
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

/*
function set_main_div(doc){
    var head = doc.match(/<head[^>]*>([\s\S]*)<\/head>/i);
    var additionalhead = head[1];
    require(['dojox.xml.parser'],
	    function(parser) {
		var head_dom = parser.parse(additionalhead);
		for (var i = 0; i < head_dom.childNodes.length; i++) {
		    console.log(head_dom.childNodes[i]);
		}
	    }
	   );

        var body = doc.match(/<body[^>]*>([\s\S]*)<\/body>/i);
        var newbody = body[1];
        require(['dojo/query', 'dojo/dom-style', 'dijit/registry', 'dojo/domReady!'],
        function(query, style, registry){
           var mainCP = registry.byId('maindiv');
           // mainCP.domNode.style.visibility = 'hidden';
           style.set(mainCP, 'visibility', 'hidden');
           mainCP.set('content', newbody);
           setup_dojo();
               mainCP.domNode.style.visibility = 'visible';
           require(['dojo/domReady!'], 
           function(){
           });
        });
}
*/

function setup_dojo() {
    require(['lsmb/lib/Loader', 'dojo/domReady!'],
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
       'dojo/on', 'dojo/query', "dojo/request/xhr", 'dojo/domReady!'
   ], function (on, query, xhr) {
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
                           load_link(xhr, node.href);
                     }
                 );
             }
        });   
    }
);
