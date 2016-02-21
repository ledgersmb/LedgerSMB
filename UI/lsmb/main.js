
require(['dojo/parser', 'dojo/query', 'dojo/on', 'dijit/registry',
         'dojo/_base/event', 'dojo/hash', 'dojo/topic', 'dojo/dom-class',
         'dojo/domReady!'],
        function(parser, query, on, registry, event, hash, topic, domClass) {
            parser.parse().then(function() {
                // delay the option of triggering load_link() until
                // the parser has run: before then, the maindiv widget
                // doesn't exist!
                var mainDiv = registry.byId('maindiv');
                query('a.menu-terminus').forEach(function(node){
                    if (node.href.search(/pl/)){
                        on(node, 'click', function(e){
                            event.stop(e);
                            hash(node.href);
                        });
                    }
                });

                if (window.location.hash) {
                    mainDiv.load_link(hash());
                }
                topic.subscribe("/dojo/hashchange", function(hash) {
                    mainDiv.load_link(hash);
                });

                query('#console-container')
                    .forEach(function(node) {
                        domClass.add(node, 'done-parsing');
                    });
                query('body')
                    .forEach(function(node) {
                        domClass.add(node, 'done-parsing');
                    });
            });
        });


require([
    'dojo/on', 'dojo/query', 'dojo/dom-class', 'dojo/_base/event',
    'dojo/domReady!'],
        function (on, query, domclass, event) {
            query('a.t-submenu').forEach(function(node){
                on(node, 'click', function(e) {
                    event.stop(e);
                    var parent = node.parentNode;
                    if (domclass.contains(parent, 'menu_closed')) {
                        domclass.replace(parent, 'menu_open', 'menu_closed');
                    }
                    else {
                        domclass.replace(parent, 'menu_closed', 'menu_open');
                    };
                });
            });
        });
