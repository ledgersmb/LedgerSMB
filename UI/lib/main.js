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

function ActivateMenu(id) {
    var obj = "menu_" + id;
    var menu_node = document.getElementById(obj);
    var href = menu_node.href;
    window.alert(href);

    return false;
}

require([
       'dojo/on', 'dojo/query', 'dojo/domReady!'
   ], function (on, query) {
        query('.menu_closed').forEach(function(node){
             on(node, 'click', function(e){
                   e.preventDefault();
                   SwitchMenu(node.id);
                }
             );
        });
   }
);
