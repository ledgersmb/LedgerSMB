//>>built
define("lsmb/ComparisonSelection", ["dijit/layout/ContentPane", "dojo/_base/declare", "dojo/dom", "dojo/topic", "dojo/dom-style"], function(d, e, f, g, c) {
  return e("lsmb/ComparisonSelection", d, {topic:"", id:"", show:function(a) {
    a && c.set(a, "display", "block")
  }, hide:function(a) {
    a && c.set(a, "display", "none")
  }, update:function(a) {
    var b = f.byId(this.id);
    "by_dates" == a ? this.show(b) : "by_periods" == a && this.hide(b)
  }, postCreate:function() {
    var a = this;
    this.inherited(arguments);
    this.container && (this.id = this.container);
    this.topic && this.own(g.subscribe(a.topic, function(b) {
      a.update(b)
    }))
  }})
});

//# sourceMappingURL=ComparisonSelection.js.map