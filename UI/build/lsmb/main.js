//>>built
require("dojo/parser dojo/query dojo/on dijit/registry dojo/_base/event dojo/hash dojo/topic dojo/dom-class dojo/domReady!".split(" "), function(a, c, d, e, h, f, k, g) {
  a.parse().then(function() {
    var a = e.byId("maindiv");
    c("a.menu-terminus").forEach(function(b) {
      b.href.search(/pl/) && d(b, "click", function(a) {
        h.stop(a);
        f(b.href)
      })
    });
    window.location.hash && a.load_link(f());
    k.subscribe("/dojo/hashchange", function(b) {
      a.load_link(b)
    });
    c("#console-container").forEach(function(b) {
      g.add(b, "done-parsing")
    });
    c("body").forEach(function(b) {
      g.add(b, "done-parsing")
    })
  })
});
require(["dojo/on", "dojo/query", "dojo/dom-class", "dojo/_base/event", "dojo/domReady!"], function(a, c, d, e) {
  c("a.t-submenu").forEach(function(c) {
    a(c, "click", function(a) {
      e.stop(a);
      a = c.parentNode;
      d.contains(a, "menu_closed") ? d.replace(a, "menu_open", "menu_closed") : d.replace(a, "menu_closed", "menu_open")
    })
  })
});

//# sourceMappingURL=main.js.map