
require(["dojo/parser", "dojo/query", "dojo/on", "dijit/registry",
         "dojo/_base/event", "dojo/hash", "dojo/topic", "dojo/dom-class",
         "dojo/ready", "dojo/domReady!"],
        function(parser, query, on, registry, event, hash, topic, domClass,
                 ready) {
            parser.parse().then(function() {
                // delay the option of triggering load_link() until
                // the parser has run: before then, the maindiv widget
                // doesn't exist!
                var mainDiv = registry.byId("maindiv");

                // we need a centralized interceptClick function so
                // the hash part we generate to make it unique, really *is*
                // Without the hash part, clicking on a link twice won't
                // reload it. That's not too bad, except if a POST was sent
                // in the mean time; which causes the page content *not* to
                // correspond (directly) to the link in the browser location,
                // yet clicking on the link won't return the user to the -e.g.-
                // search page (that is -- without the hash part below)
                var c = 0;
                var interceptClick = function (dnode) {
                    if (dnode.target || ! dnode.href)
                        return;

                    var href = dnode.href + "#s";
                    on(dnode, "click", function(e) {
                        if ( !e.ctrlKey && !e.shiftKey && !e.button != 0 ) {
                          event.stop(e);
                          c++;
                          hash(href + c.toString(16));
                          mainDiv.fade_main_div();
                        }
                    });
                    var l = window.location;
                    dnode.href = l.origin + l.pathname
                        + l.search + "#" + dnode.href.substring(l.origin.length);
                };
                if (mainDiv != null) {
                    mainDiv.interceptClick = interceptClick;
                    if (window.location.hash) {
                        mainDiv.load_link(hash());
                    }
                    topic.subscribe("/dojo/hashchange", function(hash) {
                        mainDiv.load_link(hash);
                    });
                }

                query("a.menu-terminus").forEach(interceptClick);

                ready(999, function() {
                    query("#console-container")
                        .forEach(function(node) {
                            domClass.add(node, "done-parsing");
                        });
                    query("body")
                        .forEach(function(node) {
                            domClass.add(node, "done-parsing");
                        });
                });
            });
        });
