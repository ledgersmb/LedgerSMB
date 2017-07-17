define(["dojo/_base/lang","dojo/when" /*=====, "dojo/_base/declare", "dojo/store/api/Store" =====*/],
function(lang, when /*=====, declare, Store =====*/){

// module:
//        lsmb/menus/Cache
// This is to query the masterstore and rely on it for get.
// This should be refactored to use the standard cache and only have
// a specialized getter

var Cache = function(masterStore, cachingStore, options){
    options = options || {};
    return lang.delegate(masterStore, {
        query: function(query, directives){
            var results = masterStore.query(query, directives);
            results.forEach(function(object){
                if(!options.isLoaded || options.isLoaded(object)){
                    cachingStore.put(object);
                }
            });
            return results;
        },
        // look for a queryEngine in either store
        queryEngine: masterStore.queryEngine || cachingStore.queryEngine,
        get: function(id, directives){
            return when(cachingStore.get(id), function(result){
                return result || when(masterStore.query(directives), function(result){
                    if(result){
                        result.forEach(function(child) {
                            cachingStore.put(child, {id: child.id});
                        });
                        result = cachingStore.get(id);
                    }
                    return result;
                });
            });
        },
    });
};
return Cache;
});

