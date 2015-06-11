
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
