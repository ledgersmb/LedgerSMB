//>>built
define("dojo/when",["./Deferred","./promise/Promise"],function(d,g){return function(a,c,e,f){var b=a&&"function"===typeof a.then,h=b&&a instanceof g;if(b)h||(b=new d(a.cancel),a.then(b.resolve,b.reject,b.progress),a=b.promise);else return 1<arguments.length?c?c(a):a:(new d).resolve(a);return c||e||f?a.then(c,e,f):a}});
//# sourceMappingURL=when.js.map