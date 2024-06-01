// Borrowed from dijit/registry to avoid pulling in all Dojo/Dijit

const registry = Object.create(null);

function findWidgets(root, skipNode) {
    var outAry = [];

    function getChildrenHelper (node) {
        for(var el = node.firstChild; el; el = el.nextSibling){
            if(el.getAttribute && el.getAttribute("widgetid")){
                outAry.push(el);
            }else if(el !== skipNode){
                getChildrenHelper(el);
            }
        }
    }
    getChildrenHelper(root);

    return outAry;
};

registry.findWidgets = findWidgets;

module.exports = registry;
