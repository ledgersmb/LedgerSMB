//>>built
define("dojo/request/default",["exports","require","../has"],function(a,d,c){var b=c("config-requestProvider");b||(b="./xhr");a.getPlatformDefaultId=function(){return"./xhr"};a.load=function(a,c,e,f){d(["platform"==a?"./xhr":b],function(a){e(a)})}});
//# sourceMappingURL=default.js.map