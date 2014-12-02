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
