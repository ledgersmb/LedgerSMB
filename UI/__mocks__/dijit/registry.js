/* eslint-disable no-shadow */
// Borrowed from dijit/registry to avoid pulling in all Dojo/Dijit

const registry = Object.create(null);

function findWidgets(root, skipNode) {
    var outAry = [];

    function getChildrenHelper(root){
        for(var node = root.firstChild; node; node = node.nextSibling){
            if(node.getAttribute && node.getAttribute("widgetid")){
                outAry.push(node);
            }else if(node !== skipNode){
                getChildrenHelper(node);
            }
        }
    }
    getChildrenHelper(root);

    return outAry;
};

registry.findWidgets = findWidgets;

module.exports = registry;