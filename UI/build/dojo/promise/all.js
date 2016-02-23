//>>built
define("dojo/promise/all",["../_base/array","../Deferred","../when"],function(g,k,l){var m=g.some;return function(b){var c,a;b instanceof Array?a=b:b&&"object"===typeof b&&(c=b);var d,f=[];if(c){a=[];for(var h in c)Object.hasOwnProperty.call(c,h)&&(f.push(h),a.push(c[h]));d={}}else a&&(d=[]);if(!a||!a.length)return(new k).resolve(d);var e=new k;e.promise.always(function(){d=f=null});var g=a.length;m(a,function(a,b){c||f.push(b);l(a,function(a){e.isFulfilled()||(d[f[b]]=a,0===--g&&e.resolve(d))},e.reject);
return e.isFulfilled()});return e.promise}});
//# sourceMappingURL=all.js.map