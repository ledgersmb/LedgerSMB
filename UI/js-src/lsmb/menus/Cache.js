define(["dojo/_base/lang","dojo/when" /*=====, "dojo/_base/declare", "dojo/store/api/Store" =====*/],
function(lang, when /*=====, declare, Store =====*/){

// module:
//		lsmb/menus/Cache

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
/*
        add: function(object, directives){
            return when(masterStore.add(object, directives), function(result){
                // now put result in cache
                cachingStore.add(result && typeof result == "object" ? result : object, directives);
                return result; // the result from the add should be dictated by the masterStore and be unaffected by the cachingStore
            });
        },
        put: function(object, directives){
            // first remove from the cache, so it is empty until we get a response from the master store
            cachingStore.remove((directives && directives.id) || this.getIdentity(object));
            return when(masterStore.put(object, directives), function(result){
                // now put result in cache
                cachingStore.put(result && typeof result == "object" ? result : object, directives);
                return result; // the result from the put should be dictated by the masterStore and be unaffected by the cachingStore
            });
        },
        remove: function(id, directives){
            return when(masterStore.remove(id, directives), function(result){
                return cachingStore.remove(id, directives);
            });
        },
        evict: function(id){
            return cachingStore.remove(id);
        }
*/
    });
};
//lang.setObject("lsmb.menus.Cache", Cache);
return Cache;
});

