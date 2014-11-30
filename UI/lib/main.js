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
    console.log(href);
    xhr(href, {"handlesAs": "text"}).then(function(doc){
        var body = doc.match(/<body[^>]*>([\s\S]*)<\/body>/i);
        console.log(body[1]);
        var container = document.getElementById('maindiv');
        var newbody = body[1];
        container.innerHTML= newbody;
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
