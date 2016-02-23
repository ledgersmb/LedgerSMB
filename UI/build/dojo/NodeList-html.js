//>>built
define("dojo/NodeList-html",["./query","./_base/lang","./html"],function(a,b,d){a=a.NodeList;b.extend(a,{html:function(a,b){var c=new d._ContentSetter(b||{});this.forEach(function(b){c.node=b;c.set(a);c.tearDown()});return this}});return a});
//# sourceMappingURL=NodeList-html.js.map