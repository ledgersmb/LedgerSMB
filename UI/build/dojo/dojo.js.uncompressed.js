(function(
	userConfig,
	defaultConfig
){
	// summary:
	//		This is the "source loader" and is the entry point for Dojo during development. You may also load Dojo with
	//		any AMD-compliant loader via the package main module dojo/main.
	// description:
	//		This is the "source loader" for Dojo. It provides an AMD-compliant loader that can be configured
	//		to operate in either synchronous or asynchronous modes. After the loader is defined, dojo is loaded
	//		IAW the package main module dojo/main. In the event you wish to use a foreign loader, you may load dojo as a package
	//		via the package main module dojo/main and this loader is not required; see dojo/package.json for details.
	//
	//		In order to keep compatibility with the v1.x line, this loader includes additional machinery that enables
	//		the dojo.provide, dojo.require et al API. This machinery is loaded by default, but may be dynamically removed
	//		via the has.js API and statically removed via the build system.
	//
	//		This loader includes sniffing machinery to determine the environment; the following environments are supported:
	//
	//		- browser
	//		- node.js
	//		- rhino
	//
	//		This is the so-called "source loader". As such, it includes many optional features that may be discarded by
	//		building a customized version with the build system.

	// Design and Implementation Notes
	//
	// This is a dojo-specific adaption of bdLoad, donated to the dojo foundation by Altoviso LLC.
	//
	// This function defines an AMD-compliant (http://wiki.commonjs.org/wiki/Modules/AsynchronousDefinition)
	// loader that can be configured to operate in either synchronous or asynchronous modes.
	//
	// Since this machinery implements a loader, it does not have the luxury of using a load system and/or
	// leveraging a utility library. This results in an unpleasantly long file; here is a road map of the contents:
	//
	//	 1. Small library for use implementing the loader.
	//	 2. Define the has.js API; this is used throughout the loader to bracket features.
	//	 3. Define the node.js and rhino sniffs and sniff.
	//	 4. Define the loader's data.
	//	 5. Define the configuration machinery.
	//	 6. Define the script element sniffing machinery and sniff for configuration data.
	//	 7. Configure the loader IAW the provided user, default, and sniffing data.
	//	 8. Define the global require function.
	//	 9. Define the module resolution machinery.
	//	10. Define the module and plugin module definition machinery
	//	11. Define the script injection machinery.
	//	12. Define the window load detection.
	//	13. Define the logging API.
	//	14. Define the tracing API.
	//	16. Define the AMD define function.
	//	17. Define the dojo v1.x provide/require machinery--so called "legacy" modes.
	//	18. Publish global variables.
	//
	// Language and Acronyms and Idioms
	//
	// moduleId: a CJS module identifier, (used for public APIs)
	// mid: moduleId (used internally)
	// packageId: a package identifier (used for public APIs)
	// pid: packageId (used internally); the implied system or default package has pid===""
	// pack: package is used internally to reference a package object (since javascript has reserved words including "package")
	// prid: plugin resource identifier
	// The integer constant 1 is used in place of true and 0 in place of false.

	// define a minimal library to help build the loader
	var	noop = function(){
		},

		isEmpty = function(it){
			for(var p in it){
				return 0;
			}
			return 1;
		},

		toString = {}.toString,

		isFunction = function(it){
			return toString.call(it) == "[object Function]";
		},

		isString = function(it){
			return toString.call(it) == "[object String]";
		},

		isArray = function(it){
			return toString.call(it) == "[object Array]";
		},

		forEach = function(vector, callback){
			if(vector){
				for(var i = 0; i < vector.length;){
					callback(vector[i++]);
				}
			}
		},

		mix = function(dest, src){
			for(var p in src){
				dest[p] = src[p];
			}
			return dest;
		},

		makeError = function(error, info){
			return mix(new Error(error), {src:"dojoLoader", info:info});
		},

		uidSeed = 1,

		uid = function(){
			// Returns a unique identifier (within the lifetime of the document) of the form /_d+/.
			return "_" + uidSeed++;
		},

		// FIXME: how to doc window.require() api

		// this will be the global require function; define it immediately so we can start hanging things off of it
		req = function(
			config,		  //(object, optional) hash of configuration properties
			dependencies, //(array of commonjs.moduleId, optional) list of modules to be loaded before applying callback
			callback	  //(function, optional) lambda expression to apply to module values implied by dependencies
		){
			return contextRequire(config, dependencies, callback, 0, req);
		},

		// the loader uses the has.js API to control feature inclusion/exclusion; define then use throughout
		global = this,

		doc = global.document,

		element = doc && doc.createElement("DiV"),

		has = req.has = function(name){
			return isFunction(hasCache[name]) ? (hasCache[name] = hasCache[name](global, doc, element)) : hasCache[name];
		},

		hasCache = has.cache = defaultConfig.hasCache;

	has.add = function(name, test, now, force){
		(hasCache[name]===undefined || force) && (hasCache[name] = test);
		return now && has(name);
	};

	 0 && has.add("host-node", userConfig.has && "host-node" in userConfig.has ?
		userConfig.has["host-node"] :
		(typeof process == "object" && process.versions && process.versions.node && process.versions.v8));
	if( 0 ){
		// fixup the default config for node.js environment
		require("./_base/configNode.js").config(defaultConfig);
		// remember node's require (with respect to baseUrl==dojo's root)
		defaultConfig.loaderPatch.nodeRequire = require;
	}

	 0 && has.add("host-rhino", userConfig.has && "host-rhino" in userConfig.has ?
		userConfig.has["host-rhino"] :
		(typeof load == "function" && (typeof Packages == "function" || typeof Packages == "object")));
	if( 0 ){
		// owing to rhino's lame feature that hides the source of the script, give the user a way to specify the baseUrl...
		for(var baseUrl = userConfig.baseUrl || ".", arg, rhinoArgs = this.arguments, i = 0; i < rhinoArgs.length;){
			arg = (rhinoArgs[i++] + "").split("=");
			if(arg[0] == "baseUrl"){
				baseUrl = arg[1];
				break;
			}
		}
		load(baseUrl + "/_base/configRhino.js");
		rhinoDojoConfig(defaultConfig, baseUrl, rhinoArgs);
	}

	has.add("host-webworker", ((typeof WorkerGlobalScope !== 'undefined') && (self instanceof WorkerGlobalScope)));
	if(has("host-webworker")){
		mix(defaultConfig.hasCache, {
			"host-browser": 0,
			"dom": 0,
			"dojo-dom-ready-api": 0,
			"dojo-sniff": 0,
			"dojo-inject-api": 1,
			"host-webworker": 1
		});

		defaultConfig.loaderPatch = {
			injectUrl: function(url, callback){
				// TODO:
				//		This is not async, nor can it be in Webworkers.  It could be made better by passing
				//		the entire require array into importScripts at.  This way the scripts are loaded in
				//		async mode; even if the callbacks are ran in sync.  It is not a major issue as webworkers
				//		tend to be long running where initial startup is not a major factor.

				try{
					importScripts(url);
					callback();
				}catch(e){
					console.info("failed to load resource (" + url + ")");
					console.error(e);
				}
			}
		};
	}

	// userConfig has tests override defaultConfig has tests; do this after the environment detection because
	// the environment detection usually sets some has feature values in the hasCache.
	for(var p in userConfig.has){
		has.add(p, userConfig.has[p], 0, 1);
	}

	//
	// define the loader data
	//

	// the loader will use these like symbols if the loader has the traceApi; otherwise
	// define magic numbers so that modules can be provided as part of defaultConfig
	var	requested = 1,
		arrived = 2,
		nonmodule = 3,
		executing = 4,
		executed = 5;

	if( 0 ){
		// these make debugging nice; but using strings for symbols is a gross rookie error; don't do it for production code
		requested = "requested";
		arrived = "arrived";
		nonmodule = "not-a-module";
		executing = "executing";
		executed = "executed";
	}

	var legacyMode = 0,
		sync = "sync",
		xd = "xd",
		syncExecStack = [],
		dojoRequirePlugin = 0,
		checkDojoRequirePlugin = noop,
		transformToAmd = noop,
		getXhr;
	if( 0 ){
		req.isXdUrl = noop;

		req.initSyncLoader = function(dojoRequirePlugin_, checkDojoRequirePlugin_, transformToAmd_){
			// the first dojo/_base/loader loaded gets to define these variables; they are designed to work
			// in the presence of zero to many mapped dojo/_base/loaders
			if(!dojoRequirePlugin){
				dojoRequirePlugin = dojoRequirePlugin_;
				checkDojoRequirePlugin = checkDojoRequirePlugin_;
				transformToAmd = transformToAmd_;
			}

			return {
				sync:sync,
				requested:requested,
				arrived:arrived,
				nonmodule:nonmodule,
				executing:executing,
				executed:executed,
				syncExecStack:syncExecStack,
				modules:modules,
				execQ:execQ,
				getModule:getModule,
				injectModule:injectModule,
				setArrived:setArrived,
				signal:signal,
				finishExec:finishExec,
				execModule:execModule,
				dojoRequirePlugin:dojoRequirePlugin,
				getLegacyMode:function(){return legacyMode;},
				guardCheckComplete:guardCheckComplete
			};
		};

		if( 1  || has("host-webworker")){
			// in legacy sync mode, the loader needs a minimal XHR library

			var locationProtocol = location.protocol,
				locationHost = location.host;
			req.isXdUrl = function(url){
				if(/^\./.test(url)){
					// begins with a dot is always relative to page URL; therefore not xdomain
					return false;
				}
				if(/^\/\//.test(url)){
					// for v1.6- backcompat, url starting with // indicates xdomain
					return true;
				}
				// get protocol and host
				// \/+ takes care of the typical file protocol that looks like file:///drive/path/to/file
				// locationHost is falsy if file protocol => if locationProtocol matches and is "file:", || will return false
				var match = url.match(/^([^\/\:]+\:)\/+([^\/]+)/);
				return match && (match[1] != locationProtocol || (locationHost && match[2] != locationHost));
			};


			// note: to get the file:// protocol to work in FF, you must set security.fileuri.strict_origin_policy to false in about:config
			 1 || has.add("dojo-xhr-factory", 1);
			has.add("dojo-force-activex-xhr",  1  && !doc.addEventListener && window.location.protocol == "file:");
			has.add("native-xhr", typeof XMLHttpRequest != "undefined");
			if(has("native-xhr") && !has("dojo-force-activex-xhr")){
				getXhr = function(){
					return new XMLHttpRequest();
				};
			}else{
				// if in the browser an old IE; find an xhr
				for(var XMLHTTP_PROGIDS = ['Msxml2.XMLHTTP', 'Microsoft.XMLHTTP', 'Msxml2.XMLHTTP.4.0'], progid, i = 0; i < 3;){
					try{
						progid = XMLHTTP_PROGIDS[i++];
						if(new ActiveXObject(progid)){
							// this progid works; therefore, use it from now on
							break;
						}
					}catch(e){
						// squelch; we're just trying to find a good ActiveX progid
						// if they all fail, then progid ends up as the last attempt and that will signal the error
						// the first time the client actually tries to exec an xhr
					}
				}
				getXhr = function(){
					return new ActiveXObject(progid);
				};
			}
			req.getXhr = getXhr;

			has.add("dojo-gettext-api", 1);
			req.getText = function(url, async, onLoad){
				var xhr = getXhr();
				xhr.open('GET', fixupUrl(url), false);
				xhr.send(null);
				if(xhr.status == 200 || (!location.host && !xhr.status)){
					if(onLoad){
						onLoad(xhr.responseText, async);
					}
				}else{
					throw makeError("xhrFailed", xhr.status);
				}
				return xhr.responseText;
			};
		}
	}else{
		req.async = 1;
	}

	//
	// loader eval
	//
	var eval_ =
		// use the function constructor so our eval is scoped close to (but not in) in the global space with minimal pollution
		new Function('return eval(arguments[0]);');

	req.eval =
		function(text, hint){
			return eval_(text + "\r\n//# sourceURL=" + hint);
		};

	//
	// loader micro events API
	//
	var listenerQueues = {},
		error = "error",
		signal = req.signal = function(type, args){
			var queue = listenerQueues[type];
			// notice we run a copy of the queue; this allows listeners to add/remove
			// other listeners without affecting this particular signal
			forEach(queue && queue.slice(0), function(listener){
				listener.apply(null, isArray(args) ? args : [args]);
			});
		},
		on = req.on = function(type, listener){
			// notice a queue is not created until a client actually connects
			var queue = listenerQueues[type] || (listenerQueues[type] = []);
			queue.push(listener);
			return {
				remove:function(){
					for(var i = 0; i<queue.length; i++){
						if(queue[i]===listener){
							queue.splice(i, 1);
							return;
						}
					}
				}
			};
		};

	// configuration machinery; with an optimized/built defaultConfig, all configuration machinery can be discarded
	// lexical variables hold key loader data structures to help with minification; these may be completely,
	// one-time initialized by defaultConfig for optimized/built versions
	var
		aliases
			// a vector of pairs of [regexs or string, replacement] => (alias, actual)
			= [],

		paths
			// CommonJS paths
			= {},

		pathsMapProg
			// list of (from-path, to-path, regex, length) derived from paths;
			// a "program" to apply paths; see computeMapProg
			= [],

		packs
			// a map from packageId to package configuration object; see fixupPackageInfo
			= {},

		map = req.map
			// AMD map config variable; dojo/_base/kernel needs req.map to figure out the scope map
			= {},

		mapProgs
			// vector of quads as described by computeMapProg; map-key is AMD map key, map-value is AMD map value
			= [],

		modules
			// A hash:(mid) --> (module-object) the module namespace
			//
			// pid: the package identifier to which the module belongs (e.g., "dojo"); "" indicates the system or default package
			// mid: the fully-resolved (i.e., mappings have been applied) module identifier without the package identifier (e.g., "dojo/io/script")
			// url: the URL from which the module was retrieved
			// pack: the package object of the package to which the module belongs
			// executed: 0 => not executed; executing => in the process of traversing deps and running factory; executed => factory has been executed
			// deps: the dependency vector for this module (vector of modules objects)
			// def: the factory for this module
			// result: the result of the running the factory for this module
			// injected: (0 | requested | arrived) the status of the module; nonmodule means the resource did not call define
			// load: plugin load function; applicable only for plugins
			//
			// Modules go through several phases in creation:
			//
			// 1. Requested: some other module's definition or a require application contained the requested module in
			//	  its dependency vector or executing code explicitly demands a module via req.require.
			//
			// 2. Injected: a script element has been appended to the insert-point element demanding the resource implied by the URL
			//
			// 3. Loaded: the resource injected in [2] has been evaluated.
			//
			// 4. Defined: the resource contained a define statement that advised the loader about the module. Notice that some
			//	  resources may just contain a bundle of code and never formally define a module via define
			//
			// 5. Evaluated: the module was defined via define and the loader has evaluated the factory and computed a result.
			= {},

		cacheBust
			// query string to append to module URLs to bust browser cache
			= "",

		cache
			// hash:(mid | url)-->(function | string)
			//
			// A cache of resources. The resources arrive via a config.cache object, which is a hash from either mid --> function or
			// url --> string. The url key is distinguished from the mid key by always containing the prefix "url:". url keys as provided
			// by config.cache always have a string value that represents the contents of the resource at the given url. mid keys as provided
			// by configl.cache always have a function value that causes the same code to execute as if the module was script injected.
			//
			// Both kinds of key-value pairs are entered into cache via the function consumePendingCache, which may relocate keys as given
			// by any mappings *iff* the config.cache was received as part of a module resource request.
			//
			// Further, for mid keys, the implied url is computed and the value is entered into that key as well. This allows mapped modules
			// to retrieve cached items that may have arrived consequent to another namespace.
			//
			 = {},

		urlKeyPrefix
			// the prefix to prepend to a URL key in the cache.
			= "url:",

		pendingCacheInsert
			// hash:(mid)-->(function)
			//
			// Gives a set of cache modules pending entry into cache. When cached modules are published to the loader, they are
			// entered into pendingCacheInsert; modules are then pressed into cache upon (1) AMD define or (2) upon receiving another
			// independent set of cached modules. (1) is the usual case, and this case allows normalizing mids given in the pending
			// cache for the local configuration, possibly relocating modules.
			 = {},

		dojoSniffConfig
			// map of configuration variables
			// give the data-dojo-config as sniffed from the document (if any)
			= {},

		insertPointSibling
			// the nodes used to locate where scripts are injected into the document
			= 0;

	if( 1 ){
		var consumePendingCacheInsert = function(referenceModule){
				var p, item, match, now, m;
				for(p in pendingCacheInsert){
					item = pendingCacheInsert[p];
					match = p.match(/^url\:(.+)/);
					if(match){
						cache[urlKeyPrefix + toUrl(match[1], referenceModule)] =  item;
					}else if(p=="*now"){
						now = item;
					}else if(p!="*noref"){
						m = getModuleInfo(p, referenceModule, true);
						cache[m.mid] = cache[urlKeyPrefix + m.url] = item;
					}
				}
				if(now){
					now(createRequire(referenceModule));
				}
				pendingCacheInsert = {};
			},

			escapeString = function(s){
				return s.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, function(c){ return "\\" + c; });
			},

			computeMapProg = function(map, dest){
				// This routine takes a map as represented by a JavaScript object and initializes dest, a vector of
				// quads of (map-key, map-value, refex-for-map-key, length-of-map-key), sorted decreasing by length-
				// of-map-key. The regex looks for the map-key followed by either "/" or end-of-string at the beginning
				// of a the search source. Notice the map-value is irrelevant to the algorithm
				dest.splice(0, dest.length);
				for(var p in map){
					dest.push([
						p,
						map[p],
						new RegExp("^" + escapeString(p) + "(\/|$)"),
						p.length]);
				}
				dest.sort(function(lhs, rhs){ return rhs[3] - lhs[3]; });
				return dest;
			},

			computeAliases = function(config, dest){
				forEach(config, function(pair){
					// take a fixed-up copy...
					dest.push([isString(pair[0]) ? new RegExp("^" + escapeString(pair[0]) + "$") : pair[0], pair[1]]);
				});
			},


			fixupPackageInfo = function(packageInfo){
				// calculate the precise (name, location, main, mappings) for a package
				var name = packageInfo.name;
				if(!name){
					// packageInfo must be a string that gives the name
					name = packageInfo;
					packageInfo = {name:name};
				}
				packageInfo = mix({main:"main"}, packageInfo);
				packageInfo.location = packageInfo.location ? packageInfo.location : name;

				// packageMap is deprecated in favor of AMD map
				if(packageInfo.packageMap){
					map[name] = packageInfo.packageMap;
				}

				if(!packageInfo.main.indexOf("./")){
					packageInfo.main = packageInfo.main.substring(2);
				}

				// now that we've got a fully-resolved package object, push it into the configuration
				packs[name] = packageInfo;
			},

			delayedModuleConfig
				// module config cannot be consumed until the loader is completely initialized; therefore, all
				// module config detected during booting is memorized and applied at the end of loader initialization
				// TODO: this is a bit of a kludge; all config should be moved to end of loader initialization, but
				// we'll delay this chore and do it with a final loader 1.x cleanup after the 2.x loader prototyping is complete
				= [],


			config = function(config, booting, referenceModule){
				for(var p in config){
					if(p=="waitSeconds"){
						req.waitms = (config[p] || 0) * 1000;
					}
					if(p=="cacheBust"){
						cacheBust = config[p] ? (isString(config[p]) ? config[p] : (new Date()).getTime() + "") : "";
					}
					if(p=="baseUrl" || p=="combo"){
						req[p] = config[p];
					}
					if( 0  && p=="async"){
						// falsy or "sync" => legacy sync loader
						// "xd" => sync but loading xdomain tree and therefore loading asynchronously (not configurable, set automatically by the loader)
						// "legacyAsync" => permanently in "xd" by choice
						// "debugAtAllCosts" => trying to load everything via script injection (not implemented)
						// otherwise, must be truthy => AMD
						// legacyMode: sync | legacyAsync | xd | false
						var mode = config[p];
						req.legacyMode = legacyMode = (isString(mode) && /sync|legacyAsync/.test(mode) ? mode : (!mode ? sync : false));
						req.async = !legacyMode;
					}
					if(config[p]!==hasCache){
						// accumulate raw config info for client apps which can use this to pass their own config
						req.rawConfig[p] = config[p];
						p!="has" && has.add("config-"+p, config[p], 0, booting);
					}
				}

				// make sure baseUrl exists
				if(!req.baseUrl){
					req.baseUrl = "./";
				}
				// make sure baseUrl ends with a slash
				if(!/\/$/.test(req.baseUrl)){
					req.baseUrl += "/";
				}

				// now do the special work for has, packages, packagePaths, paths, aliases, and cache

				for(p in config.has){
					has.add(p, config.has[p], 0, booting);
				}

				// for each package found in any packages config item, augment the packs map owned by the loader
				forEach(config.packages, fixupPackageInfo);

				// for each packagePath found in any packagePaths config item, augment the packageConfig
				// packagePaths is deprecated; remove in 2.0
				for(var baseUrl in config.packagePaths){
					forEach(config.packagePaths[baseUrl], function(packageInfo){
						var location = baseUrl + "/" + packageInfo;
						if(isString(packageInfo)){
							packageInfo = {name:packageInfo};
						}
						packageInfo.location = location;
						fixupPackageInfo(packageInfo);
					});
				}

				// notice that computeMapProg treats the dest as a reference; therefore, if/when that variable
				// is published (see dojo-publish-privates), the published variable will always hold a valid value.

				// this must come after all package processing since package processing may mutate map
				computeMapProg(mix(map, config.map), mapProgs);
				forEach(mapProgs, function(item){
					item[1] = computeMapProg(item[1], []);
					if(item[0]=="*"){
						mapProgs.star = item;
					}
				});

				// push in any paths and recompute the internal pathmap
				computeMapProg(mix(paths, config.paths), pathsMapProg);

				// aliases
				computeAliases(config.aliases, aliases);

				if(booting){
					delayedModuleConfig.push({config:config.config});
				}else{
					for(p in config.config){
						var module = getModule(p, referenceModule);
						module.config = mix(module.config || {}, config.config[p]);
					}
				}

				// push in any new cache values
				if(config.cache){
					consumePendingCacheInsert();
					pendingCacheInsert = config.cache;
					if(config.cache["*noref"]){
						consumePendingCacheInsert();
					}
				}

				signal("config", [config, req.rawConfig]);
			};

		//
		// execute the various sniffs; userConfig can override and value
		//

		if(has("dojo-cdn") ||  1 ){
			// the sniff regex looks for a src attribute ending in dojo.js, optionally preceded with a path.
			// match[3] returns the path to dojo.js (if any) without the trailing slash. This is used for the
			// dojo location on CDN deployments and baseUrl when either/both of these are not provided
			// explicitly in the config data; this is the 1.6- behavior.

			var scripts = doc.getElementsByTagName("script"),
				i = 0,
				script, dojoDir, src, match;
			while(i < scripts.length){
				script = scripts[i++];
				if((src = script.getAttribute("src")) && (match = src.match(/(((.*)\/)|^)dojo\.js(\W|$)/i))){
					// sniff dojoDir and baseUrl
					dojoDir = match[3] || "";
					defaultConfig.baseUrl = defaultConfig.baseUrl || dojoDir;

					// remember an insertPointSibling
					insertPointSibling = script;
				}

				// sniff configuration on attribute in script element
				if((src = (script.getAttribute("data-dojo-config") || script.getAttribute("djConfig")))){
					dojoSniffConfig = req.eval("({ " + src + " })", "data-dojo-config");

					// remember an insertPointSibling
					insertPointSibling = script;
				}

				// sniff requirejs attribute
				if( 0 ){
					if((src = script.getAttribute("data-main"))){
						dojoSniffConfig.deps = dojoSniffConfig.deps || [src];
					}
				}
			}
		}

		if( 0 ){
			// pass down doh.testConfig from parent as if it were a data-dojo-config
			try{
				if(window.parent != window && window.parent.require){
					var doh = window.parent.require("doh");
					doh && mix(dojoSniffConfig, doh.testConfig);
				}
			}catch(e){}
		}

		// configure the loader; let the user override defaults
		req.rawConfig = {};
		config(defaultConfig, 1);

		// do this before setting userConfig/sniffConfig to allow userConfig/sniff overrides
		if(has("dojo-cdn")){
			packs.dojo.location = dojoDir;
			if(dojoDir){
				dojoDir += "/";
			}
			packs.dijit.location = dojoDir + "../dijit/";
			packs.dojox.location = dojoDir + "../dojox/";
		}

		config(userConfig, 1);
		config(dojoSniffConfig, 1);

	}else{
		// no config API, assume defaultConfig has everything the loader needs...for the entire lifetime of the application
		paths = defaultConfig.paths;
		pathsMapProg = defaultConfig.pathsMapProg;
		packs = defaultConfig.packs;
		aliases = defaultConfig.aliases;
		mapProgs = defaultConfig.mapProgs;
		modules = defaultConfig.modules;
		cache = defaultConfig.cache;
		cacheBust = defaultConfig.cacheBust;

		// remember the default config for other processes (e.g., dojo/config)
		req.rawConfig = defaultConfig;
	}


	if( 0 ){
		req.combo = req.combo || {add:noop};
		var	comboPending = 0,
			combosPending = [],
			comboPendingTimer = null;
	}


	// build the loader machinery iaw configuration, including has feature tests
	var	injectDependencies = function(module){
			// checkComplete!=0 holds the idle signal; we're not idle if we're injecting dependencies
			guardCheckComplete(function(){
				forEach(module.deps, injectModule);
				if( 0  && comboPending && !comboPendingTimer){
					comboPendingTimer = setTimeout(function() {
						comboPending = 0;
						comboPendingTimer = null;
						req.combo.done(function(mids, url) {
							var onLoadCallback= function(){
								// defQ is a vector of module definitions 1-to-1, onto mids
								runDefQ(0, mids);
								checkComplete();
							};
							combosPending.push(mids);
							injectingModule = mids;
							req.injectUrl(url, onLoadCallback, mids);
							injectingModule = 0;
						}, req);
					}, 0);
				}
			});
		},

		contextRequire = function(a1, a2, a3, referenceModule, contextRequire){
			var module, syntheticMid;
			if(isString(a1)){
				// signature is (moduleId)
				module = getModule(a1, referenceModule, true);
				if(module && module.executed){
					return module.result;
				}
				throw makeError("undefinedModule", a1);
			}
			if(!isArray(a1)){
				// a1 is a configuration
				config(a1, 0, referenceModule);

				// juggle args; (a2, a3) may be (dependencies, callback)
				a1 = a2;
				a2 = a3;
			}
			if(isArray(a1)){
				// signature is (requestList [,callback])
				if(!a1.length){
					a2 && a2();
				}else{
					syntheticMid = "require*" + uid();

					// resolve the request list with respect to the reference module
					for(var mid, deps = [], i = 0; i < a1.length;){
						mid = a1[i++];
						deps.push(getModule(mid, referenceModule));
					}

					// construct a synthetic module to control execution of the requestList, and, optionally, callback
					module = mix(makeModuleInfo("", syntheticMid, 0, ""), {
						injected: arrived,
						deps: deps,
						def: a2 || noop,
						require: referenceModule ? referenceModule.require : req,
						gc: 1 //garbage collect
					});
					modules[module.mid] = module;

					// checkComplete!=0 holds the idle signal; we're not idle if we're injecting dependencies
					injectDependencies(module);

					// try to immediately execute
					// if already traversing a factory tree, then strict causes circular dependency to abort the execution; maybe
					// it's possible to execute this require later after the current traversal completes and avoid the circular dependency.
					// ...but *always* insist on immediate in synch mode
					var strict = checkCompleteGuard && legacyMode!=sync;
					guardCheckComplete(function(){
						execModule(module, strict);
					});
					if(!module.executed){
						// some deps weren't on board or circular dependency detected and strict; therefore, push into the execQ
						execQ.push(module);
					}
					checkComplete();
				}
			}
			return contextRequire;
		},

		createRequire = function(module){
			if(!module){
				return req;
			}
			var result = module.require;
			if(!result){
				result = function(a1, a2, a3){
					return contextRequire(a1, a2, a3, module, result);
				};
				module.require = mix(result, req);
				result.module = module;
				result.toUrl = function(name){
					return toUrl(name, module);
				};
				result.toAbsMid = function(mid){
					return toAbsMid(mid, module);
				};
				if( 0 ){
					result.undef = function(mid){
						req.undef(mid, module);
					};
				}
				if( 0 ){
					result.syncLoadNls = function(mid){
						var nlsModuleInfo = getModuleInfo(mid, module),
							nlsModule = modules[nlsModuleInfo.mid];
						if(!nlsModule || !nlsModule.executed){
							cached = cache[nlsModuleInfo.mid] || cache[urlKeyPrefix + nlsModuleInfo.url];
							if(cached){
								evalModuleText(cached);
								nlsModule = modules[nlsModuleInfo.mid];
							}
						}
						return nlsModule && nlsModule.executed && nlsModule.result;
					};
				}

			}
			return result;
		},

		execQ =
			// The list of modules that need to be evaluated.
			[],

		defQ =
			// The queue of define arguments sent to loader.
			[],

		waiting =
			// The set of modules upon which the loader is waiting for definition to arrive
			{},

		setRequested = function(module){
			module.injected = requested;
			waiting[module.mid] = 1;
			if(module.url){
				waiting[module.url] = module.pack || 1;
			}
			startTimer();
		},

		setArrived = function(module){
			module.injected = arrived;
			delete waiting[module.mid];
			if(module.url){
				delete waiting[module.url];
			}
			if(isEmpty(waiting)){
				clearTimer();
				 0  && legacyMode==xd && (legacyMode = sync);
			}
		},

		execComplete = req.idle =
			// says the loader has completed (or not) its work
			function(){
				return !defQ.length && isEmpty(waiting) && !execQ.length && !checkCompleteGuard;
			},

		runMapProg = function(targetMid, map){
			// search for targetMid in map; return the map item if found; falsy otherwise
			if(map){
			for(var i = 0; i < map.length; i++){
				if(map[i][2].test(targetMid)){
					return map[i];
				}
			}
			}
			return 0;
		},

		compactPath = function(path){
			var result = [],
				segment, lastSegment;
			path = path.replace(/\\/g, '/').split('/');
			while(path.length){
				segment = path.shift();
				if(segment==".." && result.length && lastSegment!=".."){
					result.pop();
					lastSegment = result[result.length - 1];
				}else if(segment!="."){
					result.push(lastSegment= segment);
				} // else ignore "."
			}
			return result.join("/");
		},

		makeModuleInfo = function(pid, mid, pack, url){
			if( 0 ){
				var xd= req.isXdUrl(url);
				return {pid:pid, mid:mid, pack:pack, url:url, executed:0, def:0, isXd:xd, isAmd:!!(xd || (packs[pid] && packs[pid].isAmd))};
			}else{
				return {pid:pid, mid:mid, pack:pack, url:url, executed:0, def:0};
			}
		},

		getModuleInfo_ = function(mid, referenceModule, packs, modules, baseUrl, mapProgs, pathsMapProg, aliases, alwaysCreate){
			// arguments are passed instead of using lexical variables so that this function my be used independent of the loader (e.g., the builder)
			// alwaysCreate is useful in this case so that getModuleInfo never returns references to real modules owned by the loader
			var pid, pack, midInPackage, mapItem, url, result, isRelative, requestedMid;
			requestedMid = mid;
			isRelative = /^\./.test(mid);
			if(/(^\/)|(\:)|(\.js$)/.test(mid) || (isRelative && !referenceModule)){
				// absolute path or protocol of .js filetype, or relative path but no reference module and therefore relative to page
				// whatever it is, it's not a module but just a URL of some sort
				// note: pid===0 indicates the routine is returning an unmodified mid

				return makeModuleInfo(0, mid, 0, mid);
			}else{
				// relative module ids are relative to the referenceModule; get rid of any dots
				mid = compactPath(isRelative ? (referenceModule.mid + "/../" + mid) : mid);
				if(/^\./.test(mid)){
					throw makeError("irrationalPath", mid);
				}
				// at this point, mid is an absolute mid

				// map the mid
				if(referenceModule){
					mapItem = runMapProg(referenceModule.mid, mapProgs);
				}
				mapItem = mapItem || mapProgs.star;
				mapItem = mapItem && runMapProg(mid, mapItem[1]);

				if(mapItem){
					mid = mapItem[1] + mid.substring(mapItem[3]);
					}

				match = mid.match(/^([^\/]+)(\/(.+))?$/);
				pid = match ? match[1] : "";
				if((pack = packs[pid])){
					mid = pid + "/" + (midInPackage = (match[3] || pack.main));
				}else{
					pid = "";
				}

				// search aliases
				var candidateLength = 0,
					candidate = 0;
				forEach(aliases, function(pair){
					var match = mid.match(pair[0]);
					if(match && match.length>candidateLength){
						candidate = isFunction(pair[1]) ? mid.replace(pair[0], pair[1]) : pair[1];
					}
				});
				if(candidate){
					return getModuleInfo_(candidate, 0, packs, modules, baseUrl, mapProgs, pathsMapProg, aliases, alwaysCreate);
				}

				result = modules[mid];
				if(result){
					return alwaysCreate ? makeModuleInfo(result.pid, result.mid, result.pack, result.url) : modules[mid];
				}
			}
			// get here iff the sought-after module does not yet exist; therefore, we need to compute the URL given the
			// fully resolved (i.e., all relative indicators and package mapping resolved) module id

			// note: pid!==0 indicates the routine is returning a url that has .js appended unmodified mid
			mapItem = runMapProg(mid, pathsMapProg);
			if(mapItem){
				url = mapItem[1] + mid.substring(mapItem[3]);
			}else if(pid){
				url = pack.location + "/" + midInPackage;
			}else if( 0 ){
				url = "../" + mid;
			}else{
				url = mid;
			}
			// if result is not absolute, add baseUrl
			if(!(/(^\/)|(\:)/.test(url))){
				url = baseUrl + url;
			}
			url += ".js";
			return makeModuleInfo(pid, mid, pack, compactPath(url));
		},

		getModuleInfo = function(mid, referenceModule, fromPendingCache){
			return getModuleInfo_(mid, referenceModule, packs, modules, req.baseUrl, fromPendingCache ? [] : mapProgs, fromPendingCache ? [] : pathsMapProg, fromPendingCache ? [] : aliases);
		},

		resolvePluginResourceId = function(plugin, prid, referenceModule){
			return plugin.normalize ? plugin.normalize(prid, function(mid){return toAbsMid(mid, referenceModule);}) : toAbsMid(prid, referenceModule);
		},

		dynamicPluginUidGenerator = 0,

		getModule = function(mid, referenceModule, immediate){
			// compute and optionally construct (if necessary) the module implied by the mid with respect to referenceModule
			var match, plugin, prid, result;
			match = mid.match(/^(.+?)\!(.*)$/);
			if(match){
				// name was <plugin-module>!<plugin-resource-id>
				plugin = getModule(match[1], referenceModule, immediate);

				if( 0  && legacyMode == sync && !plugin.executed){
					injectModule(plugin);
					if(plugin.injected===arrived && !plugin.executed){
						guardCheckComplete(function(){
							execModule(plugin);
						});
					}
					if(plugin.executed){
						promoteModuleToPlugin(plugin);
					}else{
						// we are in xdomain mode for some reason
						execQ.unshift(plugin);
					}
				}



				if(plugin.executed === executed && !plugin.load){
					// executed the module not knowing it was a plugin
					promoteModuleToPlugin(plugin);
				}

				// if the plugin has not been loaded, then can't resolve the prid and  must assume this plugin is dynamic until we find out otherwise
				if(plugin.load){
					prid = resolvePluginResourceId(plugin, match[2], referenceModule);
					mid = (plugin.mid + "!" + (plugin.dynamic ? ++dynamicPluginUidGenerator + "!" : "") + prid);
				}else{
					prid = match[2];
					mid = plugin.mid + "!" + (++dynamicPluginUidGenerator) + "!waitingForPlugin";
				}
				result = {plugin:plugin, mid:mid, req:createRequire(referenceModule), prid:prid};
			}else{
				result = getModuleInfo(mid, referenceModule);
			}
			return modules[result.mid] || (!immediate && (modules[result.mid] = result));
		},

		toAbsMid = req.toAbsMid = function(mid, referenceModule){
			return getModuleInfo(mid, referenceModule).mid;
		},

		toUrl = req.toUrl = function(name, referenceModule){
			var moduleInfo = getModuleInfo(name+"/x", referenceModule),
				url= moduleInfo.url;
			return fixupUrl(moduleInfo.pid===0 ?
				// if pid===0, then name had a protocol or absolute path; either way, toUrl is the identify function in such cases
				name :
				// "/x.js" since getModuleInfo automatically appends ".js" and we appended "/x" to make name look like a module id
				url.substring(0, url.length-5)
			);
		},

		nonModuleProps = {
			injected: arrived,
			executed: executed,
			def: nonmodule,
			result: nonmodule
		},

		makeCjs = function(mid){
			return modules[mid] = mix({mid:mid}, nonModuleProps);
		},

		cjsRequireModule = makeCjs("require"),
		cjsExportsModule = makeCjs("exports"),
		cjsModuleModule = makeCjs("module"),

		runFactory = function(module, args){
			req.trace("loader-run-factory", [module.mid]);
			var factory = module.def,
				result;
			 0  && syncExecStack.unshift(module);
			if( 0 ){
				try{
					result= isFunction(factory) ? factory.apply(null, args) : factory;
				}catch(e){
					signal(error, module.result = makeError("factoryThrew", [module, e]));
				}
			}else{
				result= isFunction(factory) ? factory.apply(null, args) : factory;
			}
			module.result = result===undefined && module.cjs ? module.cjs.exports : result;
			 0  && syncExecStack.shift(module);
		},

		abortExec = {},

		defOrder = 0,

		promoteModuleToPlugin = function(pluginModule){
			var plugin = pluginModule.result;
			pluginModule.dynamic = plugin.dynamic;
			pluginModule.normalize = plugin.normalize;
			pluginModule.load = plugin.load;
			return pluginModule;
		},

		resolvePluginLoadQ = function(plugin){
			// plugins is a newly executed module that has a loadQ waiting to run

			// step 1: traverse the loadQ and fixup the mid and prid; remember the map from original mid to new mid
			// recall the original mid was created before the plugin was on board and therefore it was impossible to
			// compute the final mid; accordingly, prid may or may not change, but the mid will definitely change
			var map = {};
			forEach(plugin.loadQ, function(pseudoPluginResource){
				// manufacture and insert the real module in modules
				var prid = resolvePluginResourceId(plugin, pseudoPluginResource.prid, pseudoPluginResource.req.module),
					mid = plugin.dynamic ? pseudoPluginResource.mid.replace(/waitingForPlugin$/, prid) : (plugin.mid + "!" + prid),
					pluginResource = mix(mix({}, pseudoPluginResource), {mid:mid, prid:prid, injected:0});
				if(!modules[mid]){
					// create a new (the real) plugin resource and inject it normally now that the plugin is on board
					injectPlugin(modules[mid] = pluginResource);
				} // else this was a duplicate request for the same (plugin, rid) for a nondynamic plugin

				// pluginResource is really just a placeholder with the wrong mid (because we couldn't calculate it until the plugin was on board)
				// mark is as arrived and delete it from modules; the real module was requested above
				map[pseudoPluginResource.mid] = modules[mid];
				setArrived(pseudoPluginResource);
				delete modules[pseudoPluginResource.mid];
			});
			plugin.loadQ = 0;

			// step2: replace all references to any placeholder modules with real modules
			var substituteModules = function(module){
				for(var replacement, deps = module.deps || [], i = 0; i<deps.length; i++){
					replacement = map[deps[i].mid];
					if(replacement){
						deps[i] = replacement;
					}
				}
			};
			for(var p in modules){
				substituteModules(modules[p]);
			}
			forEach(execQ, substituteModules);
		},

		finishExec = function(module){
			req.trace("loader-finish-exec", [module.mid]);
			module.executed = executed;
			module.defOrder = defOrder++;
			 0  && forEach(module.provides, function(cb){ cb(); });
			if(module.loadQ){
				// the module was a plugin
				promoteModuleToPlugin(module);
				resolvePluginLoadQ(module);
			}
			// remove all occurrences of this module from the execQ
			for(i = 0; i < execQ.length;){
				if(execQ[i] === module){
					execQ.splice(i, 1);
				}else{
					i++;
				}
			}
			// delete references to synthetic modules
			if (/^require\*/.test(module.mid)) {
				delete modules[module.mid];
			}
		},

		circleTrace = [],

		execModule = function(module, strict){
			// run the dependency vector, then run the factory for module
			if(module.executed === executing){
				req.trace("loader-circular-dependency", [circleTrace.concat(module.mid).join("->")]);
				return (!module.def || strict) ? abortExec :  (module.cjs && module.cjs.exports);
			}
			// at this point the module is either not executed or fully executed


			if(!module.executed){
				if(!module.def){
					return abortExec;
				}
				var mid = module.mid,
					deps = module.deps || [],
					arg, argResult,
					args = [],
					i = 0;

				if( 0 ){
					circleTrace.push(mid);
					req.trace("loader-exec-module", ["exec", circleTrace.length, mid]);
				}

				// for circular dependencies, assume the first module encountered was executed OK
				// modules that circularly depend on a module that has not run its factory will get
				// the pre-made cjs.exports===module.result. They can take a reference to this object and/or
				// add properties to it. When the module finally runs its factory, the factory can
				// read/write/replace this object. Notice that so long as the object isn't replaced, any
				// reference taken earlier while walking the deps list is still valid.
				module.executed = executing;
				while((arg = deps[i++])){
					argResult = ((arg === cjsRequireModule) ? createRequire(module) :
									((arg === cjsExportsModule) ? module.cjs.exports :
										((arg === cjsModuleModule) ? module.cjs :
											execModule(arg, strict))));
					if(argResult === abortExec){
						module.executed = 0;
						req.trace("loader-exec-module", ["abort", mid]);
						 0  && circleTrace.pop();
						return abortExec;
					}
					args.push(argResult);
				}
				runFactory(module, args);
				finishExec(module);
				 0  && circleTrace.pop();
			}
			// at this point the module is guaranteed fully executed

			return module.result;
		},


		checkCompleteGuard = 0,

		guardCheckComplete = function(proc){
			try{
				checkCompleteGuard++;
				proc();
			}finally{
				checkCompleteGuard--;
			}
			if(execComplete()){
				signal("idle", []);
			}
		},

		checkComplete = function(){
			// keep going through the execQ as long as at least one factory is executed
			// plugins, recursion, cached modules all make for many execution path possibilities
			if(checkCompleteGuard){
				return;
			}
			guardCheckComplete(function(){
				checkDojoRequirePlugin();
				for(var currentDefOrder, module, i = 0; i < execQ.length;){
					currentDefOrder = defOrder;
					module = execQ[i];
					execModule(module);
					if(currentDefOrder!=defOrder){
						// defOrder was bumped one or more times indicating something was executed (note, this indicates
						// the execQ was modified, maybe a lot (for example a later module causes an earlier module to execute)
						checkDojoRequirePlugin();
						i = 0;
					}else{
						// nothing happened; check the next module in the exec queue
						i++;
					}
				}
			});
		};


	if( 0 ){
		req.undef = function(moduleId, referenceModule){
			// In order to reload a module, it must be undefined (this routine) and then re-requested.
			// This is useful for testing frameworks (at least).
			var module = getModule(moduleId, referenceModule);
			setArrived(module);
			mix(module, {def:0, executed:0, injected:0, node:0});
		};
	}

	if( 1 ){
		if(has("dojo-loader-eval-hint-url")===undefined){
			has.add("dojo-loader-eval-hint-url", 1);
		}

		var fixupUrl= typeof userConfig.fixupUrl == "function" ? userConfig.fixupUrl : function(url){
				url += ""; // make sure url is a Javascript string (some paths may be a Java string)
				return url + (cacheBust ? ((/\?/.test(url) ? "&" : "?") + cacheBust) : "");
			},

			injectPlugin = function(
				module
			){
				// injects the plugin module given by module; may have to inject the plugin itself
				var plugin = module.plugin;

				if(plugin.executed === executed && !plugin.load){
					// executed the module not knowing it was a plugin
					promoteModuleToPlugin(plugin);
				}

				var onLoad = function(def){
						module.result = def;
						setArrived(module);
						finishExec(module);
						checkComplete();
					};

				if(plugin.load){
					plugin.load(module.prid, module.req, onLoad);
				}else if(plugin.loadQ){
					plugin.loadQ.push(module);
				}else{
					// the unshift instead of push is important: we don't want plugins to execute as
					// dependencies of some other module because this may cause circles when the plugin
					// loadQ is run; also, generally, we want plugins to run early since they may load
					// several other modules and therefore can potentially unblock many modules
					plugin.loadQ = [module];
					execQ.unshift(plugin);
					injectModule(plugin);
				}
			},

			// for IE, injecting a module may result in a recursive execution if the module is in the cache

			cached = 0,

			injectingModule = 0,

			injectingCachedModule = 0,

			evalModuleText = function(text, module){
				// see def() for the injectingCachedModule bracket; it simply causes a short, safe circuit
				if(has("config-stripStrict")){
					text = text.replace(/"use strict"/g, '');
				}
				injectingCachedModule = 1;
				if( 0 ){
					try{
						if(text===cached){
							cached.call(null);
						}else{
							req.eval(text, has("dojo-loader-eval-hint-url") ? module.url : module.mid);
						}
					}catch(e){
						signal(error, makeError("evalModuleThrew", module));
					}
				}else{
					if(text===cached){
						cached.call(null);
					}else{
						req.eval(text, has("dojo-loader-eval-hint-url") ? module.url : module.mid);
					}
				}
				injectingCachedModule = 0;
			},

			injectModule = function(module){
				// Inject the module. In the browser environment, this means appending a script element into
				// the document; in other environments, it means loading a file.
				//
				// If in synchronous mode, then get the module synchronously if it's not xdomainLoading.

				var mid = module.mid,
					url = module.url;
				if(module.executed || module.injected || waiting[mid] || (module.url && ((module.pack && waiting[module.url]===module.pack) || waiting[module.url]==1))){
					return;
				}
				setRequested(module);

				if( 0 ){
					var viaCombo = 0;
					if(module.plugin && module.plugin.isCombo){
						// a combo plugin; therefore, must be handled by combo service
						// the prid should have already been converted to a URL (if required by the plugin) during
						// the normalize process; in any event, there is no way for the loader to know how to
						// to the conversion; therefore the third argument is zero
						req.combo.add(module.plugin.mid, module.prid, 0, req);
						viaCombo = 1;
					}else if(!module.plugin){
						viaCombo = req.combo.add(0, module.mid, module.url, req);
					}
					if(viaCombo){
						comboPending= 1;
						return;
					}
				}

				if(module.plugin){
					injectPlugin(module);
					return;
				} // else a normal module (not a plugin)


				var onLoadCallback = function(){
					runDefQ(module);
					if(module.injected !== arrived){
						// the script that contained the module arrived and has been executed yet
						// nothing was added to the defQ (so it wasn't an AMD module) and the module
						// wasn't marked as arrived by dojo.provide (so it wasn't a v1.6- module);
						// therefore, it must not have been a module; adjust state accordingly
						if(has("dojo-enforceDefine")){
							signal(error, makeError("noDefine", module));
							return;
						}
						setArrived(module);
						mix(module, nonModuleProps);
						req.trace("loader-define-nonmodule", [module.url]);
					}

					if( 0  && legacyMode){
						// must call checkComplete even in for sync loader because we may be in xdomainLoading mode;
						// but, if xd loading, then don't call checkComplete until out of the current sync traversal
						// in order to preserve order of execution of the dojo.required modules
						!syncExecStack.length && checkComplete();
					}else{
						checkComplete();
					}
				};
				cached = cache[mid] || cache[urlKeyPrefix + module.url];
				if(cached){
					req.trace("loader-inject", ["cache", module.mid, url]);
					evalModuleText(cached, module);
					onLoadCallback();
					return;
				}
				if( 0  && legacyMode){
					if(module.isXd){
						// switch to async mode temporarily; if current legacyMode!=sync, then is must be one of {legacyAsync, xd, false}
						legacyMode==sync && (legacyMode = xd);
						// fall through and load via script injection
					}else if(module.isAmd && legacyMode!=sync){
						// fall through and load via script injection
					}else{
						// mode may be sync, xd/legacyAsync, or async; module may be AMD or legacy; but module is always located on the same domain
						var xhrCallback = function(text){
							if(legacyMode==sync){
								// the top of syncExecStack gives the current synchronously executing module; the loader needs
								// to know this if it has to switch to async loading in the middle of evaluating a legacy module
								// this happens when a modules dojo.require's a module that must be loaded async because it's xdomain
								// (using unshift/shift because there is no back() methods for Javascript arrays)
								syncExecStack.unshift(module);
								evalModuleText(text, module);
								syncExecStack.shift();

								// maybe the module was an AMD module
								runDefQ(module);

								// legacy modules never get to defineModule() => cjs and injected never set; also evaluation implies executing
								if(!module.cjs){
									setArrived(module);
									finishExec(module);
								}

								if(module.finish){
									// while synchronously evaluating this module, dojo.require was applied referencing a module
									// that had to be loaded async; therefore, the loader stopped answering all dojo.require
									// requests so they could be answered completely in the correct sequence; module.finish gives
									// the list of dojo.requires that must be re-applied once all target modules are available;
									// make a synthetic module to execute the dojo.require's in the correct order

									// compute a guaranteed-unique mid for the synthetic finish module; remember the finish vector; remove it from the reference module
									// TODO: can we just leave the module.finish...what's it hurting?
									var finishMid = mid + "*finish",
										finish = module.finish;
									delete module.finish;

									def(finishMid, ["dojo", ("dojo/require!" + finish.join(",")).replace(/\./g, "/")], function(dojo){
										forEach(finish, function(mid){ dojo.require(mid); });
									});
									// unshift, not push, which causes the current traversal to be reattempted from the top
									execQ.unshift(getModule(finishMid));
								}
								onLoadCallback();
							}else{
								text = transformToAmd(module, text);
								if(text){
									evalModuleText(text, module);
									onLoadCallback();
								}else{
									// if transformToAmd returned falsy, then the module was already AMD and it can be script-injected
									// do so to improve debugability(even though it means another download...which probably won't happen with a good browser cache)
									injectingModule = module;
									req.injectUrl(fixupUrl(url), onLoadCallback, module);
									injectingModule = 0;
								}
							}
						};

						req.trace("loader-inject", ["xhr", module.mid, url, legacyMode!=sync]);
						if( 0 ){
							try{
								req.getText(url, legacyMode!=sync, xhrCallback);
							}catch(e){
								signal(error, makeError("xhrInjectFailed", [module, e]));
							}
						}else{
							req.getText(url, legacyMode!=sync, xhrCallback);
						}
						return;
					}
				} // else async mode or fell through in xdomain loading mode; either way, load by script injection
				req.trace("loader-inject", ["script", module.mid, url]);
				injectingModule = module;
				req.injectUrl(fixupUrl(url), onLoadCallback, module);
				injectingModule = 0;
			},

			defineModule = function(module, deps, def){
				req.trace("loader-define-module", [module.mid, deps]);

				if( 0  && module.plugin && module.plugin.isCombo){
					// the module is a plugin resource loaded by the combo service
					// note: check for module.plugin should be enough since normal plugin resources should
					// not follow this path; module.plugin.isCombo is future-proofing belt and suspenders
					module.result = isFunction(def) ? def() : def;
					setArrived(module);
					finishExec(module);
					return module;
				}

				var mid = module.mid;
				if(module.injected === arrived){
					signal(error, makeError("multipleDefine", module));
					return module;
				}
				mix(module, {
					deps: deps,
					def: def,
					cjs: {
						id: module.mid,
						uri: module.url,
						exports: (module.result = {}),
						setExports: function(exports){
							module.cjs.exports = exports;
						},
						config:function(){
							return module.config;
						}
					}
				});

				// resolve deps with respect to this module
				for(var i = 0; deps[i]; i++){
					deps[i] = getModule(deps[i], module);
				}

				if( 0  && legacyMode && !waiting[mid]){
					// the module showed up without being asked for; it was probably in a <script> element
					injectDependencies(module);
					execQ.push(module);
					checkComplete();
				}
				setArrived(module);

				if(!isFunction(def) && !deps.length){
					module.result = def;
					finishExec(module);
				}

				return module;
			},

			runDefQ = function(referenceModule, mids){
				// defQ is an array of [id, dependencies, factory]
				// mids (if any) is a vector of mids given by a combo service
				var definedModules = [],
					module, args;
				while(defQ.length){
					args = defQ.shift();
					mids && (args[0]= mids.shift());
					// explicit define indicates possible multiple modules in a single file; delay injecting dependencies until defQ fully
					// processed since modules earlier in the queue depend on already-arrived modules that are later in the queue
					// TODO: what if no args[0] and no referenceModule
					module = (args[0] && getModule(args[0])) || referenceModule;
					definedModules.push([module, args[1], args[2]]);
				}
				consumePendingCacheInsert(referenceModule);
				forEach(definedModules, function(args){
					injectDependencies(defineModule.apply(null, args));
				});
			};
	}

	var timerId = 0,
		clearTimer = noop,
		startTimer = noop;
	if( 0 ){
		// Timer machinery that monitors how long the loader is waiting and signals an error when the timer runs out.
		clearTimer = function(){
			timerId && clearTimeout(timerId);
			timerId = 0;
		};

		startTimer = function(){
			clearTimer();
			if(req.waitms){
				timerId = global.setTimeout(function(){
					clearTimer();
					signal(error, makeError("timeout", waiting));
				}, req.waitms);
			}
		};
	}

	if ( 1 ) {
		// Test for IE's different way of signaling when scripts finish loading.  Note that according to
		// http://bugs.dojotoolkit.org/ticket/15096#comment:14, IE9 also needs to follow the
		// IE specific code path even though it has an addEventListener() method.
		// Unknown if special path needed on IE10+, which also has a document.attachEvent() method.
		// Should evaluate to false for Opera and Windows 8 apps, even though they document.attachEvent()
		//  is defined in both those environments.
		has.add("ie-event-behavior", doc.attachEvent && typeof Windows === "undefined" &&
			(typeof opera === "undefined" || opera.toString() != "[object Opera]"));
	}

	if( 1  && ( 1  ||  1 )){
		var domOn = function(node, eventName, ieEventName, handler){
				// Add an event listener to a DOM node using the API appropriate for the current browser;
				// return a function that will disconnect the listener.
				if(!has("ie-event-behavior")){
					node.addEventListener(eventName, handler, false);
					return function(){
						node.removeEventListener(eventName, handler, false);
					};
				}else{
					node.attachEvent(ieEventName, handler);
					return function(){
						node.detachEvent(ieEventName, handler);
					};
				}
			},
			windowOnLoadListener = domOn(window, "load", "onload", function(){
				req.pageLoaded = 1;
				doc.readyState!="complete" && (doc.readyState = "complete");
				windowOnLoadListener();
			});

		if( 1 ){
			// if the loader is on the page, there must be at least one script element
			// getting its parent and then doing insertBefore solves the "Operation Aborted"
			// error in IE from appending to a node that isn't properly closed; see
			// dojo/tests/_base/loader/requirejs/simple-badbase.html for an example
			// don't use scripts with type dojo/... since these may be removed; see #15809
			// prefer to use the insertPoint computed during the config sniff in case a script is removed; see #16958
			var scripts = doc.getElementsByTagName("script"),
				i = 0,
				script;
			while(!insertPointSibling){
				if(!/^dojo/.test((script = scripts[i++]) && script.type)){
					insertPointSibling= script;
				}
			}

			req.injectUrl = function(url, callback, owner){
				// insert a script element to the insert-point element with src=url;
				// apply callback upon detecting the script has loaded.

				var node = owner.node = doc.createElement("script"),
					onLoad = function(e){
						e = e || window.event;
						var node = e.target || e.srcElement;
						if(e.type === "load" || /complete|loaded/.test(node.readyState)){
							loadDisconnector();
							errorDisconnector();
							callback && callback();
						}
					},
					loadDisconnector = domOn(node, "load", "onreadystatechange", onLoad),
					errorDisconnector = domOn(node, "error", "onerror", function(e){
						loadDisconnector();
						errorDisconnector();
						signal(error, makeError("scriptError", [url, e]));
					});

				node.type = "text/javascript";
				node.charset = "utf-8";
				node.src = url;
				insertPointSibling.parentNode.insertBefore(node, insertPointSibling);
				return node;
			};
		}
	}

	if( 0 ){
		req.log = function(){
			try{
				for(var i = 0; i < arguments.length; i++){
					console.log(arguments[i]);
				}
			}catch(e){}
		};
	}else{
		req.log = noop;
	}

	if( 0 ){
		var trace = req.trace = function(
			group,	// the trace group to which this application belongs
			args	// the contents of the trace
		){
			///
			// Tracing interface by group.
			//
			// Sends the contents of args to the console iff (req.trace.on && req.trace[group])

			if(trace.on && trace.group[group]){
				signal("trace", [group, args]);
				for(var arg, dump = [], text= "trace:" + group + (args.length ? (":" + args[0]) : ""), i= 1; i<args.length;){
					arg = args[i++];
					if(isString(arg)){
						text += ", " + arg;
					}else{
						dump.push(arg);
					}
				}
				req.log(text);
				dump.length && dump.push(".");
				req.log.apply(req, dump);
			}
		};
		mix(trace, {
			on:1,
			group:{},
			set:function(group, value){
				if(isString(group)){
					trace.group[group]= value;
				}else{
					mix(trace.group, group);
				}
			}
		});
		trace.set(mix(mix(mix({}, defaultConfig.trace), userConfig.trace), dojoSniffConfig.trace));
		on("config", function(config){
			config.trace && trace.set(config.trace);
		});
	}else{
		req.trace = noop;
	}

	var def = function(
		mid,		  //(commonjs.moduleId, optional)
		dependencies, //(array of commonjs.moduleId, optional) list of modules to be loaded before running factory
		factory		  //(any)
	){
		///
		// Advises the loader of a module factory. //Implements http://wiki.commonjs.org/wiki/Modules/AsynchronousDefinition.
		///
		//note
		// CommonJS factory scan courtesy of http://requirejs.org

		var arity = arguments.length,
			defaultDeps = ["require", "exports", "module"],
			// the predominate signature...
			args = [0, mid, dependencies];
		if(arity==1){
			args = [0, (isFunction(mid) ? defaultDeps : []), mid];
		}else if(arity==2 && isString(mid)){
			args = [mid, (isFunction(dependencies) ? defaultDeps : []), dependencies];
		}else if(arity==3){
			args = [mid, dependencies, factory];
		}

		if( 0  && args[1]===defaultDeps){
			args[2].toString()
				.replace(/(\/\*([\s\S]*?)\*\/|\/\/(.*)$)/mg, "")
				.replace(/require\(["']([\w\!\-_\.\/]+)["']\)/g, function(match, dep){
				args[1].push(dep);
			});
		}

		req.trace("loader-define", args.slice(0, 2));
		var targetModule = args[0] && getModule(args[0]),
			module;
		if(targetModule && !waiting[targetModule.mid]){
			// given a mid that hasn't been requested; therefore, defined through means other than injecting
			// consequent to a require() or define() application; examples include defining modules on-the-fly
			// due to some code path or including a module in a script element. In any case,
			// there is no callback waiting to finish processing and nothing to trigger the defQ and the
			// dependencies are never requested; therefore, do it here.
			injectDependencies(defineModule(targetModule, args[1], args[2]));
		}else if(!has("ie-event-behavior") || ! 1  || injectingCachedModule){
			// not IE path: anonymous module and therefore must have been injected; therefore, onLoad will fire immediately
			// after script finishes being evaluated and the defQ can be run from that callback to detect the module id
			defQ.push(args);
		}else{
			// IE path: possibly anonymous module and therefore injected; therefore, cannot depend on 1-to-1,
			// in-order exec of onLoad with script eval (since it's IE) and must manually detect here
			targetModule = targetModule || injectingModule;
			if(!targetModule){
				for(mid in waiting){
					module = modules[mid];
					if(module && module.node && module.node.readyState === 'interactive'){
						targetModule = module;
						break;
					}
				}
				if( 0  && !targetModule){
					for(var i = 0; i<combosPending.length; i++){
						targetModule = combosPending[i];
						if(targetModule.node && targetModule.node.readyState === 'interactive'){
							break;
						}
						targetModule= 0;
					}
				}
			}
			if( 0  && isArray(targetModule)){
				injectDependencies(defineModule(getModule(targetModule.shift()), args[1], args[2]));
				if(!targetModule.length){
					combosPending.splice(i, 1);
				}
			}else if(targetModule){
				consumePendingCacheInsert(targetModule);
				injectDependencies(defineModule(targetModule, args[1], args[2]));
			}else{
				signal(error, makeError("ieDefineFailed", args[0]));
			}
			checkComplete();
		}
	};
	def.amd = {
		vendor:"dojotoolkit.org"
	};

	if( 0 ){
		req.def = def;
	}

	// allow config to override default implementation of named functions; this is useful for
	// non-browser environments, e.g., overriding injectUrl, getText, log, etc. in node.js, Rhino, etc.
	// also useful for testing and monkey patching loader
	mix(mix(req, defaultConfig.loaderPatch), userConfig.loaderPatch);

	// now that req is fully initialized and won't change, we can hook it up to the error signal
	on(error, function(arg){
		try{
			console.error(arg);
			if(arg instanceof Error){
				for(var p in arg){
					console.log(p + ":", arg[p]);
				}
				console.log(".");
			}
		}catch(e){}
	});

	// always publish these
	mix(req, {
		uid:uid,
		cache:cache,
		packs:packs
	});


	if( 0 ){
		mix(req, {
			// these may be interesting to look at when debugging
			paths:paths,
			aliases:aliases,
			modules:modules,
			legacyMode:legacyMode,
			execQ:execQ,
			defQ:defQ,
			waiting:waiting,

			// these are used for testing
			// TODO: move testing infrastructure to a different has feature
			packs:packs,
			mapProgs:mapProgs,
			pathsMapProg:pathsMapProg,
			listenerQueues:listenerQueues,

			// these are used by the builder (at least)
			computeMapProg:computeMapProg,
			computeAliases:computeAliases,
			runMapProg:runMapProg,
			compactPath:compactPath,
			getModuleInfo:getModuleInfo_
		});
	}

	// the loader can be defined exactly once; look for global define which is the symbol AMD loaders are
	// *required* to define (as opposed to require, which is optional)
	if(global.define){
		if( 0 ){
			signal(error, makeError("defineAlreadyDefined", 0));
		}
		return;
	}else{
		global.define = def;
		global.require = req;
		if( 0 ){
			require = req;
		}
	}

	if( 0  && req.combo && req.combo.plugins){
		var plugins = req.combo.plugins,
			pluginName;
		for(pluginName in plugins){
			mix(mix(getModule(pluginName), plugins[pluginName]), {isCombo:1, executed:"executed", load:1});
		}
	}

	if( 1 ){
		forEach(delayedModuleConfig, function(c){ config(c); });
		var bootDeps = dojoSniffConfig.deps ||	userConfig.deps || defaultConfig.deps,
			bootCallback = dojoSniffConfig.callback || userConfig.callback || defaultConfig.callback;
		req.boot = (bootDeps || bootCallback) ? [bootDeps || [], bootCallback] : 0;
	}
	if(! 1 ){
		!req.async && req(["dojo"]);
		req.boot && req.apply(null, req.boot);
	}
})
(this.dojoConfig || this.djConfig || this.require || {}, {
		async:1,
		hasCache:{
				'config-selectorEngine':"lite",
				'config-tlmSiblingOfDojo':1,
				'dojo-built':1,
				'dojo-loader':1,
				dom:1,
				'host-browser':1
		},
		packages:[
				{
					 location:"../lsmb",
					 main:"src",
					 name:"lsmb"
				},
				{
					 location:"../dijit",
					 name:"dijit"
				},
				{
					 location:".",
					 name:"dojo"
				}
		]
});require({cache:{
'dojo/sniff':function(){
define(["./has"], function(has){
	// module:
	//		dojo/sniff

	/*=====
	return function(){
		// summary:
		//		This module sets has() flags based on the current browser.
		//		It returns the has() function.
	};
	=====*/

	if( 1 ){
		var n = navigator,
			dua = n.userAgent,
			dav = n.appVersion,
			tv = parseFloat(dav);

		has.add("air", dua.indexOf("AdobeAIR") >= 0);
		has.add("msapp", parseFloat(dua.split("MSAppHost/")[1]) || undefined);
		has.add("khtml", dav.indexOf("Konqueror") >= 0 ? tv : undefined);
		has.add("webkit", parseFloat(dua.split("WebKit/")[1]) || undefined);
		has.add("chrome", parseFloat(dua.split("Chrome/")[1]) || undefined);
		has.add("safari", dav.indexOf("Safari")>=0 && !has("chrome") ? parseFloat(dav.split("Version/")[1]) : undefined);
		has.add("mac", dav.indexOf("Macintosh") >= 0);
		has.add("quirks", document.compatMode == "BackCompat");
		if(dua.match(/(iPhone|iPod|iPad)/)){
			var p = RegExp.$1.replace(/P/, "p");
			var v = dua.match(/OS ([\d_]+)/) ? RegExp.$1 : "1";
			var os = parseFloat(v.replace(/_/, ".").replace(/_/g, ""));
			has.add(p, os);		// "iphone", "ipad" or "ipod"
			has.add("ios", os);
		}
		has.add("android", parseFloat(dua.split("Android ")[1]) || undefined);
		has.add("bb", (dua.indexOf("BlackBerry") >= 0 || dua.indexOf("BB10") >= 0) && parseFloat(dua.split("Version/")[1]) || undefined);
		has.add("trident", parseFloat(dav.split("Trident/")[1]) || undefined);

		has.add("svg", typeof SVGAngle !== "undefined");

		if(!has("webkit")){
			// Opera
			if(dua.indexOf("Opera") >= 0){
				// see http://dev.opera.com/articles/view/opera-ua-string-changes and http://www.useragentstring.com/pages/Opera/
				// 9.8 has both styles; <9.8, 9.9 only old style
				has.add("opera", tv >= 9.8 ? parseFloat(dua.split("Version/")[1]) || tv : tv);
			}

			// Mozilla and firefox
			if(dua.indexOf("Gecko") >= 0 && !has("khtml") && !has("webkit") && !has("trident")){
				has.add("mozilla", tv);
			}
			if(has("mozilla")){
				//We really need to get away from this. Consider a sane isGecko approach for the future.
				has.add("ff", parseFloat(dua.split("Firefox/")[1] || dua.split("Minefield/")[1]) || undefined);
			}

			// IE
			if(document.all && !has("opera")){
				var isIE = parseFloat(dav.split("MSIE ")[1]) || undefined;

				//In cases where the page has an HTTP header or META tag with
				//X-UA-Compatible, then it is in emulation mode.
				//Make sure isIE reflects the desired version.
				//document.documentMode of 5 means quirks mode.
				//Only switch the value if documentMode's major version
				//is different from isIE's major version.
				var mode = document.documentMode;
				if(mode && mode != 5 && Math.floor(isIE) != mode){
					isIE = mode;
				}

				has.add("ie", isIE);
			}

			// Wii
			has.add("wii", typeof opera != "undefined" && opera.wiiremote);
		}
	}

	return has;
});

},
'dojo/on':function(){
define(["./has!dom-addeventlistener?:./aspect", "./_base/kernel", "./sniff"], function(aspect, dojo, has){

	"use strict";
	if( 1 ){ // check to make sure we are in a browser, this module should work anywhere
		var major = window.ScriptEngineMajorVersion;
		has.add("jscript", major && (major() + ScriptEngineMinorVersion() / 10));
		has.add("event-orientationchange", has("touch") && !has("android")); // TODO: how do we detect this?
		has.add("event-stopimmediatepropagation", window.Event && !!window.Event.prototype && !!window.Event.prototype.stopImmediatePropagation);
		has.add("event-focusin", function(global, doc, element){
			return 'onfocusin' in element;
		});
		
		if(has("touch")){
			has.add("touch-can-modify-event-delegate", function(){
				// This feature test checks whether deleting a property of an event delegate works
				// for a touch-enabled device. If it works, event delegation can be used as fallback
				// for browsers such as Safari in older iOS where deleting properties of the original
				// event does not work.
				var EventDelegate = function(){};
				EventDelegate.prototype =
					document.createEvent("MouseEvents"); // original event
				// Attempt to modify a property of an event delegate and check if
				// it succeeds. Depending on browsers and on whether dojo/on's
				// strict mode is stripped in a Dojo build, there are 3 known behaviors:
				// it may either succeed, or raise an error, or fail to set the property
				// without raising an error.
				try{
					var eventDelegate = new EventDelegate;
					eventDelegate.target = null;
					return eventDelegate.target === null;
				}catch(e){
					return false; // cannot use event delegation
				}
			});
		}
	}
	var on = function(target, type, listener, dontFix){
		// summary:
		//		A function that provides core event listening functionality. With this function
		//		you can provide a target, event type, and listener to be notified of
		//		future matching events that are fired.
		// target: Element|Object
		//		This is the target object or DOM element that to receive events from
		// type: String|Function
		//		This is the name of the event to listen for or an extension event type.
		// listener: Function
		//		This is the function that should be called when the event fires.
		// returns: Object
		//		An object with a remove() method that can be used to stop listening for this
		//		event.
		// description:
		//		To listen for "click" events on a button node, we can do:
		//		|	define(["dojo/on"], function(on){
		//		|		on(button, "click", clickHandler);
		//		|		...
		//		Evented JavaScript objects can also have their own events.
		//		|	var obj = new Evented;
		//		|	on(obj, "foo", fooHandler);
		//		And then we could publish a "foo" event:
		//		|	on.emit(obj, "foo", {key: "value"});
		//		We can use extension events as well. For example, you could listen for a tap gesture:
		//		|	define(["dojo/on", "dojo/gesture/tap", function(on, tap){
		//		|		on(button, tap, tapHandler);
		//		|		...
		//		which would trigger fooHandler. Note that for a simple object this is equivalent to calling:
		//		|	obj.onfoo({key:"value"});
		//		If you use on.emit on a DOM node, it will use native event dispatching when possible.

		if(typeof target.on == "function" && typeof type != "function" && !target.nodeType){
			// delegate to the target's on() method, so it can handle it's own listening if it wants (unless it 
			// is DOM node and we may be dealing with jQuery or Prototype's incompatible addition to the
			// Element prototype 
			return target.on(type, listener);
		}
		// delegate to main listener code
		return on.parse(target, type, listener, addListener, dontFix, this);
	};
	on.pausable =  function(target, type, listener, dontFix){
		// summary:
		//		This function acts the same as on(), but with pausable functionality. The
		//		returned signal object has pause() and resume() functions. Calling the
		//		pause() method will cause the listener to not be called for future events. Calling the
		//		resume() method will cause the listener to again be called for future events.
		var paused;
		var signal = on(target, type, function(){
			if(!paused){
				return listener.apply(this, arguments);
			}
		}, dontFix);
		signal.pause = function(){
			paused = true;
		};
		signal.resume = function(){
			paused = false;
		};
		return signal;
	};
	on.once = function(target, type, listener, dontFix){
		// summary:
		//		This function acts the same as on(), but will only call the listener once. The 
		//		listener will be called for the first
		//		event that takes place and then listener will automatically be removed.
		var signal = on(target, type, function(){
			// remove this listener
			signal.remove();
			// proceed to call the listener
			return listener.apply(this, arguments);
		});
		return signal;
	};
	on.parse = function(target, type, listener, addListener, dontFix, matchesTarget){
		if(type.call){
			// event handler function
			// on(node, touch.press, touchListener);
			return type.call(matchesTarget, target, listener);
		}

		if(type instanceof Array){
			// allow an array of event names (or event handler functions)
			events = type;
		}else if(type.indexOf(",") > -1){
			// we allow comma delimited event names, so you can register for multiple events at once
			var events = type.split(/\s*,\s*/);
		} 
		if(events){
			var handles = [];
			var i = 0;
			var eventName;
			while(eventName = events[i++]){
				handles.push(on.parse(target, eventName, listener, addListener, dontFix, matchesTarget));
			}
			handles.remove = function(){
				for(var i = 0; i < handles.length; i++){
					handles[i].remove();
				}
			};
			return handles;
		}
		return addListener(target, type, listener, dontFix, matchesTarget);
	};
	var touchEvents = /^touch/;
	function addListener(target, type, listener, dontFix, matchesTarget){
		// event delegation:
		var selector = type.match(/(.*):(.*)/);
		// if we have a selector:event, the last one is interpreted as an event, and we use event delegation
		if(selector){
			type = selector[2];
			selector = selector[1];
			// create the extension event for selectors and directly call it
			return on.selector(selector, type).call(matchesTarget, target, listener);
		}
		// test to see if it a touch event right now, so we don't have to do it every time it fires
		if(has("touch")){
			if(touchEvents.test(type)){
				// touch event, fix it
				listener = fixTouchListener(listener);
			}
			if(!has("event-orientationchange") && (type == "orientationchange")){
				//"orientationchange" not supported <= Android 2.1, 
				//but works through "resize" on window
				type = "resize"; 
				target = window;
				listener = fixTouchListener(listener);
			} 
		}
		if(addStopImmediate){
			// add stopImmediatePropagation if it doesn't exist
			listener = addStopImmediate(listener);
		}
		// normal path, the target is |this|
		if(target.addEventListener){
			// the target has addEventListener, which should be used if available (might or might not be a node, non-nodes can implement this method as well)
			// check for capture conversions
			var capture = type in captures,
				adjustedType = capture ? captures[type] : type;
			target.addEventListener(adjustedType, listener, capture);
			// create and return the signal
			return {
				remove: function(){
					target.removeEventListener(adjustedType, listener, capture);
				}
			};
		}
		type = "on" + type;
		if(fixAttach && target.attachEvent){
			return fixAttach(target, type, listener);
		}
		throw new Error("Target must be an event emitter");
	}
	on.matches = function(node, selector, context, children, matchesTarget) {
		// summary:
		//		Check if a node match the current selector within the constraint of a context
		// node: DOMNode
		//		The node that originate the event
		// selector: String
		//		The selector to check against
		// context: DOMNode
		//		The context to search in.
		// children: Boolean
		//		Indicates if children elements of the selector should be allowed. This defaults to
		//		true
		// matchesTarget: Object|dojo/query?
		//		An object with a property "matches" as a function. Default is dojo/query.
		//		Matching DOMNodes will be done against this function
		//		The function must return a Boolean.
		//		It will have 3 arguments: "node", "selector" and "context"
		//		True is expected if "node" is matching the current "selector" in the passed "context"
		// returns: DOMNode?
		//		The matching node, if any. Else you get false

		// see if we have a valid matchesTarget or default to dojo/query
		matchesTarget = matchesTarget && matchesTarget.matches ? matchesTarget : dojo.query;
		children = children !== false;
		// there is a selector, so make sure it matches
		if(node.nodeType != 1){
			// text node will fail in native match selector
			node = node.parentNode;
		}
		while(!matchesTarget.matches(node, selector, context)){
			if(node == context || children === false || !(node = node.parentNode) || node.nodeType != 1){ // intentional assignment
				return false;
			}
		}
		return node;
	}
	on.selector = function(selector, eventType, children){
		// summary:
		//		Creates a new extension event with event delegation. This is based on
		//		the provided event type (can be extension event) that
		//		only calls the listener when the CSS selector matches the target of the event.
		//
		//		The application must require() an appropriate level of dojo/query to handle the selector.
		// selector:
		//		The CSS selector to use for filter events and determine the |this| of the event listener.
		// eventType:
		//		The event to listen for
		// children:
		//		Indicates if children elements of the selector should be allowed. This defaults to 
		//		true
		// example:
		// |	require(["dojo/on", "dojo/mouse", "dojo/query!css2"], function(on, mouse){
		// |		on(node, on.selector(".my-class", mouse.enter), handlerForMyHover);
		return function(target, listener){
			// if the selector is function, use it to select the node, otherwise use the matches method
			var matchesTarget = typeof selector == "function" ? {matches: selector} : this,
				bubble = eventType.bubble;
			function select(eventTarget){
				return on.matches(eventTarget, selector, target, children, matchesTarget);
			}
			if(bubble){
				// the event type doesn't naturally bubble, but has a bubbling form, use that, and give it the selector so it can perform the select itself
				return on(target, bubble(select), listener);
			}
			// standard event delegation
			return on(target, eventType, function(event){
				// call select to see if we match
				var eventTarget = select(event.target);
				// if it matches we call the listener
				if (eventTarget) {
					return listener.call(eventTarget, event);
				}
			});
		};
	};

	function syntheticPreventDefault(){
		this.cancelable = false;
		this.defaultPrevented = true;
	}
	function syntheticStopPropagation(){
		this.bubbles = false;
	}
	var slice = [].slice,
		syntheticDispatch = on.emit = function(target, type, event){
		// summary:
		//		Fires an event on the target object.
		// target:
		//		The target object to fire the event on. This can be a DOM element or a plain 
		//		JS object. If the target is a DOM element, native event emitting mechanisms
		//		are used when possible.
		// type:
		//		The event type name. You can emulate standard native events like "click" and 
		//		"mouseover" or create custom events like "open" or "finish".
		// event:
		//		An object that provides the properties for the event. See https://developer.mozilla.org/en/DOM/event.initEvent 
		//		for some of the properties. These properties are copied to the event object.
		//		Of particular importance are the cancelable and bubbles properties. The
		//		cancelable property indicates whether or not the event has a default action
		//		that can be cancelled. The event is cancelled by calling preventDefault() on
		//		the event object. The bubbles property indicates whether or not the
		//		event will bubble up the DOM tree. If bubbles is true, the event will be called
		//		on the target and then each parent successively until the top of the tree
		//		is reached or stopPropagation() is called. Both bubbles and cancelable 
		//		default to false.
		// returns:
		//		If the event is cancelable and the event is not cancelled,
		//		emit will return true. If the event is cancelable and the event is cancelled,
		//		emit will return false.
		// details:
		//		Note that this is designed to emit events for listeners registered through
		//		dojo/on. It should actually work with any event listener except those
		//		added through IE's attachEvent (IE8 and below's non-W3C event emitting
		//		doesn't support custom event types). It should work with all events registered
		//		through dojo/on. Also note that the emit method does do any default
		//		action, it only returns a value to indicate if the default action should take
		//		place. For example, emitting a keypress event would not cause a character
		//		to appear in a textbox.
		// example:
		//		To fire our own click event
		//	|	require(["dojo/on", "dojo/dom"
		//	|	], function(on, dom){
		//	|		on.emit(dom.byId("button"), "click", {
		//	|			cancelable: true,
		//	|			bubbles: true,
		//	|			screenX: 33,
		//	|			screenY: 44
		//	|		});
		//		We can also fire our own custom events:
		//	|		on.emit(dom.byId("slider"), "slide", {
		//	|			cancelable: true,
		//	|			bubbles: true,
		//	|			direction: "left-to-right"
		//	|		});
		//	|	});
		var args = slice.call(arguments, 2);
		var method = "on" + type;
		if("parentNode" in target){
			// node (or node-like), create event controller methods
			var newEvent = args[0] = {};
			for(var i in event){
				newEvent[i] = event[i];
			}
			newEvent.preventDefault = syntheticPreventDefault;
			newEvent.stopPropagation = syntheticStopPropagation;
			newEvent.target = target;
			newEvent.type = type;
			event = newEvent;
		}
		do{
			// call any node which has a handler (note that ideally we would try/catch to simulate normal event propagation but that causes too much pain for debugging)
			target[method] && target[method].apply(target, args);
			// and then continue up the parent node chain if it is still bubbling (if started as bubbles and stopPropagation hasn't been called)
		}while(event && event.bubbles && (target = target.parentNode));
		return event && event.cancelable && event; // if it is still true (was cancelable and was cancelled), return the event to indicate default action should happen
	};
	var captures = has("event-focusin") ? {} : {focusin: "focus", focusout: "blur"};
	if(!has("event-stopimmediatepropagation")){
		var stopImmediatePropagation =function(){
			this.immediatelyStopped = true;
			this.modified = true; // mark it as modified so the event will be cached in IE
		};
		var addStopImmediate = function(listener){
			return function(event){
				if(!event.immediatelyStopped){// check to make sure it hasn't been stopped immediately
					event.stopImmediatePropagation = stopImmediatePropagation;
					return listener.apply(this, arguments);
				}
			};
		}
	} 
	if(has("dom-addeventlistener")){
		// emitter that works with native event handling
		on.emit = function(target, type, event){
			if(target.dispatchEvent && document.createEvent){
				// use the native event emitting mechanism if it is available on the target object
				// create a generic event				
				// we could create branch into the different types of event constructors, but 
				// that would be a lot of extra code, with little benefit that I can see, seems 
				// best to use the generic constructor and copy properties over, making it 
				// easy to have events look like the ones created with specific initializers
				var ownerDocument = target.ownerDocument || document;
				var nativeEvent = ownerDocument.createEvent("HTMLEvents");
				nativeEvent.initEvent(type, !!event.bubbles, !!event.cancelable);
				// and copy all our properties over
				for(var i in event){
					if(!(i in nativeEvent)){
						nativeEvent[i] = event[i];
					}
				}
				return target.dispatchEvent(nativeEvent) && nativeEvent;
			}
			return syntheticDispatch.apply(on, arguments); // emit for a non-node
		};
	}else{
		// no addEventListener, basically old IE event normalization
		on._fixEvent = function(evt, sender){
			// summary:
			//		normalizes properties on the event object including event
			//		bubbling methods, keystroke normalization, and x/y positions
			// evt:
			//		native event object
			// sender:
			//		node to treat as "currentTarget"
			if(!evt){
				var w = sender && (sender.ownerDocument || sender.document || sender).parentWindow || window;
				evt = w.event;
			}
			if(!evt){return evt;}
			try{
				if(lastEvent && evt.type == lastEvent.type  && evt.srcElement == lastEvent.target){
					// should be same event, reuse event object (so it can be augmented);
					// accessing evt.srcElement rather than evt.target since evt.target not set on IE until fixup below
					evt = lastEvent;
				}
			}catch(e){
				// will occur on IE on lastEvent.type reference if lastEvent points to a previous event that already
				// finished bubbling, but the setTimeout() to clear lastEvent hasn't fired yet
			}
			if(!evt.target){ // check to see if it has been fixed yet
				evt.target = evt.srcElement;
				evt.currentTarget = (sender || evt.srcElement);
				if(evt.type == "mouseover"){
					evt.relatedTarget = evt.fromElement;
				}
				if(evt.type == "mouseout"){
					evt.relatedTarget = evt.toElement;
				}
				if(!evt.stopPropagation){
					evt.stopPropagation = stopPropagation;
					evt.preventDefault = preventDefault;
				}
				switch(evt.type){
					case "keypress":
						var c = ("charCode" in evt ? evt.charCode : evt.keyCode);
						if (c==10){
							// CTRL-ENTER is CTRL-ASCII(10) on IE, but CTRL-ENTER on Mozilla
							c=0;
							evt.keyCode = 13;
						}else if(c==13||c==27){
							c=0; // Mozilla considers ENTER and ESC non-printable
						}else if(c==3){
							c=99; // Mozilla maps CTRL-BREAK to CTRL-c
						}
						// Mozilla sets keyCode to 0 when there is a charCode
						// but that stops the event on IE.
						evt.charCode = c;
						_setKeyChar(evt);
						break;
				}
			}
			return evt;
		};
		var lastEvent, IESignal = function(handle){
			this.handle = handle;
		};
		IESignal.prototype.remove = function(){
			delete _dojoIEListeners_[this.handle];
		};
		var fixListener = function(listener){
			// this is a minimal function for closing on the previous listener with as few as variables as possible
			return function(evt){
				evt = on._fixEvent(evt, this);
				var result = listener.call(this, evt);
				if(evt.modified){
					// cache the last event and reuse it if we can
					if(!lastEvent){
						setTimeout(function(){
							lastEvent = null;
						});
					}
					lastEvent = evt;
				}
				return result;
			};
		};
		var fixAttach = function(target, type, listener){
			listener = fixListener(listener);
			if(((target.ownerDocument ? target.ownerDocument.parentWindow : target.parentWindow || target.window || window) != top || 
						has("jscript") < 5.8) && 
					!has("config-_allow_leaks")){
				// IE will leak memory on certain handlers in frames (IE8 and earlier) and in unattached DOM nodes for JScript 5.7 and below.
				// Here we use global redirection to solve the memory leaks
				if(typeof _dojoIEListeners_ == "undefined"){
					_dojoIEListeners_ = [];
				}
				var emitter = target[type];
				if(!emitter || !emitter.listeners){
					var oldListener = emitter;
					emitter = Function('event', 'var callee = arguments.callee; for(var i = 0; i<callee.listeners.length; i++){var listener = _dojoIEListeners_[callee.listeners[i]]; if(listener){listener.call(this,event);}}');
					emitter.listeners = [];
					target[type] = emitter;
					emitter.global = this;
					if(oldListener){
						emitter.listeners.push(_dojoIEListeners_.push(oldListener) - 1);
					}
				}
				var handle;
				emitter.listeners.push(handle = (emitter.global._dojoIEListeners_.push(listener) - 1));
				return new IESignal(handle);
			}
			return aspect.after(target, type, listener, true);
		};

		var _setKeyChar = function(evt){
			evt.keyChar = evt.charCode ? String.fromCharCode(evt.charCode) : '';
			evt.charOrCode = evt.keyChar || evt.keyCode;	// TODO: remove for 2.0
		};
		// Called in Event scope
		var stopPropagation = function(){
			this.cancelBubble = true;
		};
		var preventDefault = on._preventDefault = function(){
			// Setting keyCode to 0 is the only way to prevent certain keypresses (namely
			// ctrl-combinations that correspond to menu accelerator keys).
			// Otoh, it prevents upstream listeners from getting this information
			// Try to split the difference here by clobbering keyCode only for ctrl
			// combinations. If you still need to access the key upstream, bubbledKeyCode is
			// provided as a workaround.
			this.bubbledKeyCode = this.keyCode;
			if(this.ctrlKey){
				try{
					// squelch errors when keyCode is read-only
					// (e.g. if keyCode is ctrl or shift)
					this.keyCode = 0;
				}catch(e){
				}
			}
			this.defaultPrevented = true;
			this.returnValue = false;
			this.modified = true; // mark it as modified  (for defaultPrevented flag) so the event will be cached in IE
		};
	}
	if(has("touch")){ 
		var EventDelegate = function(){};
		var windowOrientation = window.orientation; 
		var fixTouchListener = function(listener){ 
			return function(originalEvent){ 
				//Event normalization(for ontouchxxx and resize): 
				//1.incorrect e.pageX|pageY in iOS 
				//2.there are no "e.rotation", "e.scale" and "onorientationchange" in Android
				//3.More TBD e.g. force | screenX | screenX | clientX | clientY | radiusX | radiusY

				// see if it has already been corrected
				var event = originalEvent.corrected;
				if(!event){
					var type = originalEvent.type;
					try{
						delete originalEvent.type; // on some JS engines (android), deleting properties makes them mutable
					}catch(e){} 
					if(originalEvent.type){
						// Deleting the property of the original event did not work (this is the case of
						// browsers such as older Safari iOS), hence fallback:
						if(has("touch-can-modify-event-delegate")){
							// If deleting properties of delegated event works, use event delegation:
							EventDelegate.prototype = originalEvent;
							event = new EventDelegate;
						}else{
							// Otherwise last fallback: other browsers, such as mobile Firefox, do not like
							// delegated properties, so we have to copy
							event = {};
							for(var name in originalEvent){
								event[name] = originalEvent[name];
							}
						}
						// have to delegate methods to make them work
						event.preventDefault = function(){
							originalEvent.preventDefault();
						};
						event.stopPropagation = function(){
							originalEvent.stopPropagation();
						};
					}else{
						// deletion worked, use property as is
						event = originalEvent;
						event.type = type;
					}
					originalEvent.corrected = event;
					if(type == 'resize'){
						if(windowOrientation == window.orientation){ 
							return null;//double tap causes an unexpected 'resize' in Android
						} 
						windowOrientation = window.orientation;
						event.type = "orientationchange"; 
						return listener.call(this, event);
					}
					// We use the original event and augment, rather than doing an expensive mixin operation
					if(!("rotation" in event)){ // test to see if it has rotation
						event.rotation = 0; 
						event.scale = 1;
					}
					//use event.changedTouches[0].pageX|pageY|screenX|screenY|clientX|clientY|target
					var firstChangeTouch = event.changedTouches[0];
					for(var i in firstChangeTouch){ // use for-in, we don't need to have dependency on dojo/_base/lang here
						delete event[i]; // delete it first to make it mutable
						event[i] = firstChangeTouch[i];
					}
				}
				return listener.call(this, event); 
			}; 
		}; 
	}
	return on;
});

},
'dojo/has':function(){
define(["require", "module"], function(require, module){
	// module:
	//		dojo/has
	// summary:
	//		Defines the has.js API and several feature tests used by dojo.
	// description:
	//		This module defines the has API as described by the project has.js with the following additional features:
	//
	//		- the has test cache is exposed at has.cache.
	//		- the method has.add includes a forth parameter that controls whether or not existing tests are replaced
	//		- the loader's has cache may be optionally copied into this module's has cahce.
	//
	//		This module adopted from https://github.com/phiggins42/has.js; thanks has.js team!

	// try to pull the has implementation from the loader; both the dojo loader and bdLoad provide one
	// if using a foreign loader, then the has cache may be initialized via the config object for this module
	// WARNING: if a foreign loader defines require.has to be something other than the has.js API, then this implementation fail
	var has = require.has || function(){};
	if(! 1 ){
		var
			isBrowser =
				// the most fundamental decision: are we in the browser?
				typeof window != "undefined" &&
				typeof location != "undefined" &&
				typeof document != "undefined" &&
				window.location == location && window.document == document,

			// has API variables
			global = (function () { return this; })(),
			doc = isBrowser && document,
			element = doc && doc.createElement("DiV"),
			cache = (module.config && module.config()) || {};

		has = function(name){
			// summary:
			//		Return the current value of the named feature.
			//
			// name: String|Integer
			//		The name (if a string) or identifier (if an integer) of the feature to test.
			//
			// description:
			//		Returns the value of the feature named by name. The feature must have been
			//		previously added to the cache by has.add.

			return typeof cache[name] == "function" ? (cache[name] = cache[name](global, doc, element)) : cache[name]; // Boolean
		};

		has.cache = cache;

		has.add = function(name, test, now, force){
			// summary:
			//	 	Register a new feature test for some named feature.
			// name: String|Integer
			//	 	The name (if a string) or identifier (if an integer) of the feature to test.
			// test: Function
			//		 A test function to register. If a function, queued for testing until actually
			//		 needed. The test function should return a boolean indicating
			//	 	the presence of a feature or bug.
			// now: Boolean?
			//		 Optional. Omit if `test` is not a function. Provides a way to immediately
			//		 run the test and cache the result.
			// force: Boolean?
			//	 	Optional. If the test already exists and force is truthy, then the existing
			//	 	test will be replaced; otherwise, add does not replace an existing test (that
			//	 	is, by default, the first test advice wins).
			// example:
			//		A redundant test, testFn with immediate execution:
			//	|	has.add("javascript", function(){ return true; }, true);
			//
			// example:
			//		Again with the redundantness. You can do this in your tests, but we should
			//		not be doing this in any internal has.js tests
			//	|	has.add("javascript", true);
			//
			// example:
			//		Three things are passed to the testFunction. `global`, `document`, and a generic element
			//		from which to work your test should the need arise.
			//	|	has.add("bug-byid", function(g, d, el){
			//	|		// g	== global, typically window, yadda yadda
			//	|		// d	== document object
			//	|		// el == the generic element. a `has` element.
			//	|		return false; // fake test, byid-when-form-has-name-matching-an-id is slightly longer
			//	|	});

			(typeof cache[name]=="undefined" || force) && (cache[name]= test);
			return now && has(name);
		};

		// since we're operating under a loader that doesn't provide a has API, we must explicitly initialize
		// has as it would have otherwise been initialized by the dojo loader; use has.add to the builder
		// can optimize these away iff desired
		 1 || has.add("host-browser", isBrowser);
		 0 && has.add("host-node", (typeof process == "object" && process.versions && process.versions.node && process.versions.v8));
		 0 && has.add("host-rhino", (typeof load == "function" && (typeof Packages == "function" || typeof Packages == "object")));
		 1 || has.add("dom", isBrowser);
		 1 || has.add("dojo-dom-ready-api", 1);
		 1 || has.add("dojo-sniff", 1);
	}

	if( 1 ){
		// Common application level tests
		has.add("dom-addeventlistener", !!document.addEventListener);

		// Do the device and browser have touch capability?
		has.add("touch", "ontouchstart" in document
			|| ("onpointerdown" in document && navigator.maxTouchPoints > 0)
			|| window.navigator.msMaxTouchPoints);

		// Touch events support
		has.add("touch-events", "ontouchstart" in document);

		// Pointer Events support
		has.add("pointer-events", "onpointerdown" in document);
		has.add("MSPointer", "msMaxTouchPoints" in navigator); //IE10 (+IE11 preview)

		// I don't know if any of these tests are really correct, just a rough guess
		has.add("device-width", screen.availWidth || innerWidth);

		// Tests for DOMNode.attributes[] behavior:
		//	 - dom-attributes-explicit - attributes[] only lists explicitly user specified attributes
		//	 - dom-attributes-specified-flag (IE8) - need to check attr.specified flag to skip attributes user didn't specify
		//	 - Otherwise, in IE6-7. attributes[] will list hundreds of values, so need to do outerHTML to get attrs instead.
		var form = document.createElement("form");
		has.add("dom-attributes-explicit", form.attributes.length == 0); // W3C
		has.add("dom-attributes-specified-flag", form.attributes.length > 0 && form.attributes.length < 40);	// IE8
	}

	has.clearElement = function(element){
		// summary:
		//	 Deletes the contents of the element passed to test functions.
		element.innerHTML= "";
		return element;
	};

	has.normalize = function(id, toAbsMid){
		// summary:
		//	 Resolves id into a module id based on possibly-nested tenary expression that branches on has feature test value(s).
		//
		// toAbsMid: Function
		//	 Resolves a relative module id into an absolute module id
		var
			tokens = id.match(/[\?:]|[^:\?]*/g), i = 0,
			get = function(skip){
				var term = tokens[i++];
				if(term == ":"){
					// empty string module name, resolves to 0
					return 0;
				}else{
					// postfixed with a ? means it is a feature to branch on, the term is the name of the feature
					if(tokens[i++] == "?"){
						if(!skip && has(term)){
							// matched the feature, get the first value from the options
							return get();
						}else{
							// did not match, get the second value, passing over the first
							get(true);
							return get(skip);
						}
					}
					// a module
					return term || 0;
				}
			};
		id = get();
		return id && toAbsMid(id);
	};

	has.load = function(id, parentRequire, loaded){
		// summary:
		//		Conditional loading of AMD modules based on a has feature test value.
		// id: String
		//		Gives the resolved module id to load.
		// parentRequire: Function
		//		The loader require function with respect to the module that contained the plugin resource in it's
		//		dependency list.
		// loaded: Function
		//	 Callback to loader that consumes result of plugin demand.

		if(id){
			parentRequire([id], loaded);
		}else{
			loaded();
		}
	};

	return has;
});

},
'dojo/selector/lite':function(){
define(["../has", "../_base/kernel"], function(has, dojo){
"use strict";

var testDiv = document.createElement("div");
var matchesSelector = testDiv.matches || testDiv.webkitMatchesSelector || testDiv.mozMatchesSelector || testDiv.msMatchesSelector || testDiv.oMatchesSelector;
var querySelectorAll = testDiv.querySelectorAll;
var unionSplit = /([^\s,](?:"(?:\\.|[^"])+"|'(?:\\.|[^'])+'|[^,])*)/g;
has.add("dom-matches-selector", !!matchesSelector);
has.add("dom-qsa", !!querySelectorAll); 

// this is a simple query engine. It has handles basic selectors, and for simple
// common selectors is extremely fast
var liteEngine = function(selector, root){
	// summary:
	//		A small lightweight query selector engine that implements CSS2.1 selectors
	//		minus pseudo-classes and the sibling combinator, plus CSS3 attribute selectors

	if(combine && selector.indexOf(',') > -1){
		return combine(selector, root);
	}
	// use the root's ownerDocument if provided, otherwise try to use dojo.doc. Note 
	// that we don't use dojo/_base/window's doc to reduce dependencies, and 
	// fallback to plain document if dojo.doc hasn't been defined (by dojo/_base/window).
	// presumably we will have a better way to do this in 2.0 
	var doc = root ? root.ownerDocument || root : dojo.doc || document, 
		match = (querySelectorAll ? 
			/^([\w]*)#([\w\-]+$)|^(\.)([\w\-\*]+$)|^(\w+$)/ : // this one only matches on simple queries where we can beat qSA with specific methods
			/^([\w]*)#([\w\-]+)(?:\s+(.*))?$|(?:^|(>|.+\s+))([\w\-\*]+)(\S*$)/) // this one matches parts of the query that we can use to speed up manual filtering
			.exec(selector);
	root = root || doc;
	if(match){
		// fast path regardless of whether or not querySelectorAll exists
		if(match[2]){
			// an #id
			// use dojo.byId if available as it fixes the id retrieval in IE, note that we can't use the dojo namespace in 2.0, but if there is a conditional module use, we will use that
			var found = dojo.byId ? dojo.byId(match[2], doc) : doc.getElementById(match[2]);
			if(!found || (match[1] && match[1] != found.tagName.toLowerCase())){
				// if there is a tag qualifer and it doesn't match, no matches
				return [];
			}
			if(root != doc){
				// there is a root element, make sure we are a child of it
				var parent = found;
				while(parent != root){
					parent = parent.parentNode;
					if(!parent){
						return [];
					}
				}
			}
			return match[3] ?
					liteEngine(match[3], found) 
					: [found];
		}
		if(match[3] && root.getElementsByClassName){
			// a .class
			return root.getElementsByClassName(match[4]);
		}
		var found;
		if(match[5]){
			// a tag
			found = root.getElementsByTagName(match[5]);
			if(match[4] || match[6]){
				selector = (match[4] || "") + match[6];
			}else{
				// that was the entirety of the query, return results
				return found;
			}
		}
	}
	if(querySelectorAll){
		// qSA works strangely on Element-rooted queries
		// We can work around this by specifying an extra ID on the root
		// and working up from there (Thanks to Andrew Dupont for the technique)
		// IE 8 doesn't work on object elements
		if (root.nodeType === 1 && root.nodeName.toLowerCase() !== "object"){				
			return useRoot(root, selector, root.querySelectorAll);
		}else{
			// we can use the native qSA
			return root.querySelectorAll(selector);
		}
	}else if(!found){
		// search all children and then filter
		found = root.getElementsByTagName("*");
	}
	// now we filter the nodes that were found using the matchesSelector
	var results = [];
	for(var i = 0, l = found.length; i < l; i++){
		var node = found[i];
		if(node.nodeType == 1 && jsMatchesSelector(node, selector, root)){
			// keep the nodes that match the selector
			results.push(node);
		}
	}
	return results;
};
var useRoot = function(context, query, method){
	// this function creates a temporary id so we can do rooted qSA queries, this is taken from sizzle
	var oldContext = context,
		old = context.getAttribute("id"),
		nid = old || "__dojo__",
		hasParent = context.parentNode,
		relativeHierarchySelector = /^\s*[+~]/.test(query);

	if(relativeHierarchySelector && !hasParent){
		return [];
	}
	if(!old){
		context.setAttribute("id", nid);
	}else{
		nid = nid.replace(/'/g, "\\$&");
	}
	if(relativeHierarchySelector && hasParent){
		context = context.parentNode;
	}
	var selectors = query.match(unionSplit);
	for(var i = 0; i < selectors.length; i++){
		selectors[i] = "[id='" + nid + "'] " + selectors[i];
	}
	query = selectors.join(",");

	try{
		return method.call(context, query);
	}finally{
		if(!old){
			oldContext.removeAttribute("id");
		}
	}
};

if(!has("dom-matches-selector")){
	var jsMatchesSelector = (function(){
		// a JS implementation of CSS selector matching, first we start with the various handlers
		var caseFix = testDiv.tagName == "div" ? "toLowerCase" : "toUpperCase";
		var selectorTypes = {
			"": function(tagName){
				tagName = tagName[caseFix]();
				return function(node){
					return node.tagName == tagName;
				};
			},
			".": function(className){
				var classNameSpaced = ' ' + className + ' ';
				return function(node){
					return node.className.indexOf(className) > -1 && (' ' + node.className + ' ').indexOf(classNameSpaced) > -1;
				};
			},
			"#": function(id){
				return function(node){
					return node.id == id;
				};
			}
		};
		var attrComparators = {
			"^=": function(attrValue, value){
				return attrValue.indexOf(value) == 0;
			},
			"*=": function(attrValue, value){
				return attrValue.indexOf(value) > -1;
			},
			"$=": function(attrValue, value){
				return attrValue.substring(attrValue.length - value.length, attrValue.length) == value;
			},
			"~=": function(attrValue, value){
				return (' ' + attrValue + ' ').indexOf(' ' + value + ' ') > -1;
			},
			"|=": function(attrValue, value){
				return (attrValue + '-').indexOf(value + '-') == 0;
			},
			"=": function(attrValue, value){
				return attrValue == value;
			},
			"": function(attrValue, value){
				return true;
			}
		};
		function attr(name, value, type){
			var firstChar = value.charAt(0);
			if(firstChar == '"' || firstChar == "'"){
				// it is quoted, remove the quotes
				value = value.slice(1, -1);
			}
			value = value.replace(/\\/g,'');
			var comparator = attrComparators[type || ""];
			return function(node){
				var attrValue = node.getAttribute(name);
				return attrValue && comparator(attrValue, value);
			};
		}
		function ancestor(matcher){
			return function(node, root){
				while((node = node.parentNode) != root){
					if(matcher(node, root)){
						return true;
					}
				}
			};
		}
		function parent(matcher){
			return function(node, root){
				node = node.parentNode;
				return matcher ? 
					node != root && matcher(node, root)
					: node == root;
			};
		}
		var cache = {};
		function and(matcher, next){
			return matcher ?
				function(node, root){
					return next(node) && matcher(node, root);
				}
				: next;
		}
		return function(node, selector, root){
			// this returns true or false based on if the node matches the selector (optionally within the given root)
			var matcher = cache[selector]; // check to see if we have created a matcher function for the given selector
			if(!matcher){
				// create a matcher function for the given selector
				// parse the selectors
				if(selector.replace(/(?:\s*([> ])\s*)|(#|\.)?((?:\\.|[\w-])+)|\[\s*([\w-]+)\s*(.?=)?\s*("(?:\\.|[^"])+"|'(?:\\.|[^'])+'|(?:\\.|[^\]])*)\s*\]/g, function(t, combinator, type, value, attrName, attrType, attrValue){
					if(value){
						matcher = and(matcher, selectorTypes[type || ""](value.replace(/\\/g, '')));
					}
					else if(combinator){
						matcher = (combinator == " " ? ancestor : parent)(matcher);
					}
					else if(attrName){
						matcher = and(matcher, attr(attrName, attrValue, attrType));
					}
					return "";
				})){
					throw new Error("Syntax error in query");
				}
				if(!matcher){
					return true;
				}
				cache[selector] = matcher;
			}
			// now run the matcher function on the node
			return matcher(node, root);
		};
	})();
}
if(!has("dom-qsa")){
	var combine = function(selector, root){
		// combined queries
		var selectors = selector.match(unionSplit);
		var indexed = [];
		// add all results and keep unique ones, this only runs in IE, so we take advantage 
		// of known IE features, particularly sourceIndex which is unique and allows us to 
		// order the results 
		for(var i = 0; i < selectors.length; i++){
			selector = new String(selectors[i].replace(/\s*$/,''));
			selector.indexOf = escape; // keep it from recursively entering combine
			var results = liteEngine(selector, root);
			for(var j = 0, l = results.length; j < l; j++){
				var node = results[j];
				indexed[node.sourceIndex] = node;
			}
		}
		// now convert from a sparse array to a dense array
		var totalResults = [];
		for(i in indexed){
			totalResults.push(indexed[i]);
		}
		return totalResults;
	};
}

liteEngine.match = matchesSelector ? function(node, selector, root){
	if(root && root.nodeType != 9){
		// doesn't support three args, use rooted id trick
		return useRoot(root, selector, function(query){
			return matchesSelector.call(node, query);
		});
	}
	// we have a native matchesSelector, use that
	return matchesSelector.call(node, selector);
} : jsMatchesSelector; // otherwise use the JS matches impl

return liteEngine;
});

},
'dojo/selector/_loader':function(){
define(["../has", "require"],
		function(has, require){

"use strict";
var testDiv = document.createElement("div");
has.add("dom-qsa2.1", !!testDiv.querySelectorAll);
has.add("dom-qsa3", function(){
			// test to see if we have a reasonable native selector engine available
			try{
				testDiv.innerHTML = "<p class='TEST'></p>"; // test kind of from sizzle
				// Safari can't handle uppercase or unicode characters when
				// in quirks mode, IE8 can't handle pseudos like :empty
				return testDiv.querySelectorAll(".TEST:empty").length == 1;
			}catch(e){}
		});
var fullEngine;
var acme = "./acme", lite = "./lite";
return {
	// summary:
	//		This module handles loading the appropriate selector engine for the given browser

	load: function(id, parentRequire, loaded, config){
		var req = require;
		// here we implement the default logic for choosing a selector engine
		id = id == "default" ? has("config-selectorEngine") || "css3" : id;
		id = id == "css2" || id == "lite" ? lite :
				id == "css2.1" ? has("dom-qsa2.1") ? lite : acme :
				id == "css3" ? has("dom-qsa3") ? lite : acme :
				id == "acme" ? acme : (req = parentRequire) && id;
		if(id.charAt(id.length-1) == '?'){
			id = id.substring(0,id.length - 1);
			var optionalLoad = true;
		}
		// the query engine is optional, only load it if a native one is not available or existing one has not been loaded
		if(optionalLoad && (has("dom-compliant-qsa") || fullEngine)){
			return loaded(fullEngine);
		}
		// load the referenced selector engine
		req([id], function(engine){
			if(id != "./lite"){
				fullEngine = engine;
			}
			loaded(engine);
		});
	}
};
});

},
'dojo/query':function(){
define(["./_base/kernel", "./has", "./dom", "./on", "./_base/array", "./_base/lang", "./selector/_loader", "./selector/_loader!default"],
	function(dojo, has, dom, on, array, lang, loader, defaultEngine){

	"use strict";

	has.add("array-extensible", function(){
		// test to see if we can extend an array (not supported in old IE)
		return lang.delegate([], {length: 1}).length == 1 && !has("bug-for-in-skips-shadowed");
	});
	
	var ap = Array.prototype, aps = ap.slice, apc = ap.concat, forEach = array.forEach;

	var tnl = function(/*Array*/ a, /*dojo/NodeList?*/ parent, /*Function?*/ NodeListCtor){
		// summary:
		//		decorate an array to make it look like a `dojo/NodeList`.
		// a:
		//		Array of nodes to decorate.
		// parent:
		//		An optional parent NodeList that generated the current
		//		list of nodes. Used to call _stash() so the parent NodeList
		//		can be accessed via end() later.
		// NodeListCtor:
		//		An optional constructor function to use for any
		//		new NodeList calls. This allows a certain chain of
		//		NodeList calls to use a different object than dojo/NodeList.
		var nodeList = new (NodeListCtor || this._NodeListCtor || nl)(a);
		return parent ? nodeList._stash(parent) : nodeList;
	};

	var loopBody = function(f, a, o){
		a = [0].concat(aps.call(a, 0));
		o = o || dojo.global;
		return function(node){
			a[0] = node;
			return f.apply(o, a);
		};
	};

	// adapters

	var adaptAsForEach = function(f, o){
		// summary:
		//		adapts a single node function to be used in the forEach-type
		//		actions. The initial object is returned from the specialized
		//		function.
		// f: Function
		//		a function to adapt
		// o: Object?
		//		an optional context for f
		return function(){
			this.forEach(loopBody(f, arguments, o));
			return this;	// Object
		};
	};

	var adaptAsMap = function(f, o){
		// summary:
		//		adapts a single node function to be used in the map-type
		//		actions. The return is a new array of values, as via `dojo/_base/array.map`
		// f: Function
		//		a function to adapt
		// o: Object?
		//		an optional context for f
		return function(){
			return this.map(loopBody(f, arguments, o));
		};
	};

	var adaptAsFilter = function(f, o){
		// summary:
		//		adapts a single node function to be used in the filter-type actions
		// f: Function
		//		a function to adapt
		// o: Object?
		//		an optional context for f
		return function(){
			return this.filter(loopBody(f, arguments, o));
		};
	};

	var adaptWithCondition = function(f, g, o){
		// summary:
		//		adapts a single node function to be used in the map-type
		//		actions, behaves like forEach() or map() depending on arguments
		// f: Function
		//		a function to adapt
		// g: Function
		//		a condition function, if true runs as map(), otherwise runs as forEach()
		// o: Object?
		//		an optional context for f and g
		return function(){
			var a = arguments, body = loopBody(f, a, o);
			if(g.call(o || dojo.global, a)){
				return this.map(body);	// self
			}
			this.forEach(body);
			return this;	// self
		};
	};

	var NodeList = function(array){
		// summary:
		//		Array-like object which adds syntactic
		//		sugar for chaining, common iteration operations, animation, and
		//		node manipulation. NodeLists are most often returned as the
		//		result of dojo/query() calls.
		// description:
		//		NodeList instances provide many utilities that reflect
		//		core Dojo APIs for Array iteration and manipulation, DOM
		//		manipulation, and event handling. Instead of needing to dig up
		//		functions in the dojo package, NodeLists generally make the
		//		full power of Dojo available for DOM manipulation tasks in a
		//		simple, chainable way.
		// example:
		//		create a node list from a node
		//		|	require(["dojo/query", "dojo/dom"
		//		|	], function(query, dom){
		//		|		query.NodeList(dom.byId("foo"));
		//		|	});
		// example:
		//		get a NodeList from a CSS query and iterate on it
		//		|	require(["dojo/on", "dojo/dom"
		//		|	], function(on, dom){
		//		|		var l = query(".thinger");
		//		|		l.forEach(function(node, index, nodeList){
		//		|			console.log(index, node.innerHTML);
		//		|		});
		//		|	});
		// example:
		//		use native and Dojo-provided array methods to manipulate a
		//		NodeList without needing to use dojo.* functions explicitly:
		//		|	require(["dojo/query", "dojo/dom-construct", "dojo/dom"
		//		|	], function(query, domConstruct, dom){
		//		|		var l = query(".thinger");
		//		|		// since NodeLists are real arrays, they have a length
		//		|		// property that is both readable and writable and
		//		|		// push/pop/shift/unshift methods
		//		|		console.log(l.length);
		//		|		l.push(domConstruct.create("span"));
		//		|
		//		|		// dojo's normalized array methods work too:
		//		|		console.log( l.indexOf(dom.byId("foo")) );
		//		|		// ...including the special "function as string" shorthand
		//		|		console.log( l.every("item.nodeType == 1") );
		//		|
		//		|		// NodeLists can be [..] indexed, or you can use the at()
		//		|		// function to get specific items wrapped in a new NodeList:
		//		|		var node = l[3]; // the 4th element
		//		|		var newList = l.at(1, 3); // the 2nd and 4th elements
		//		|	});
		// example:
		//		chainability is a key advantage of NodeLists:
		//		|	require(["dojo/query", "dojo/NodeList-dom"
		//		|	], function(query){
		//		|		query(".thinger")
		//		|			.onclick(function(e){ /* ... */ })
		//		|			.at(1, 3, 8) // get a subset
		//		|				.style("padding", "5px")
		//		|				.forEach(console.log);
		//		|	});

		var isNew = this instanceof nl && has("array-extensible");
		if(typeof array == "number"){
			array = Array(array);
		}
		var nodeArray = (array && "length" in array) ? array : arguments;
		if(isNew || !nodeArray.sort){
			// make sure it's a real array before we pass it on to be wrapped 
			var target = isNew ? this : [],
				l = target.length = nodeArray.length;
			for(var i = 0; i < l; i++){
				target[i] = nodeArray[i];
			}
			if(isNew){
				// called with new operator, this means we are going to use this instance and push
				// the nodes on to it. This is usually much faster since the NodeList properties
				//	don't need to be copied (unless the list of nodes is extremely large).
				return target;
			}
			nodeArray = target;
		}
		// called without new operator, use a real array and copy prototype properties,
		// this is slower and exists for back-compat. Should be removed in 2.0.
		lang._mixin(nodeArray, nlp);
		nodeArray._NodeListCtor = function(array){
			// call without new operator to preserve back-compat behavior
			return nl(array);
		};
		return nodeArray;
	};
	
	var nl = NodeList, nlp = nl.prototype = 
		has("array-extensible") ? [] : {};// extend an array if it is extensible

	// expose adapters and the wrapper as private functions

	nl._wrap = nlp._wrap = tnl;
	nl._adaptAsMap = adaptAsMap;
	nl._adaptAsForEach = adaptAsForEach;
	nl._adaptAsFilter  = adaptAsFilter;
	nl._adaptWithCondition = adaptWithCondition;

	// mass assignment

	// add array redirectors
	forEach(["slice", "splice"], function(name){
		var f = ap[name];
		//Use a copy of the this array via this.slice() to allow .end() to work right in the splice case.
		// CANNOT apply ._stash()/end() to splice since it currently modifies
		// the existing this array -- it would break backward compatibility if we copy the array before
		// the splice so that we can use .end(). So only doing the stash option to this._wrap for slice.
		nlp[name] = function(){ return this._wrap(f.apply(this, arguments), name == "slice" ? this : null); };
	});
	// concat should be here but some browsers with native NodeList have problems with it

	// add array.js redirectors
	forEach(["indexOf", "lastIndexOf", "every", "some"], function(name){
		var f = array[name];
		nlp[name] = function(){ return f.apply(dojo, [this].concat(aps.call(arguments, 0))); };
	});

	lang.extend(NodeList, {
		// copy the constructors
		constructor: nl,
		_NodeListCtor: nl,
		toString: function(){
			// Array.prototype.toString can't be applied to objects, so we use join
			return this.join(",");
		},
		_stash: function(parent){
			// summary:
			//		private function to hold to a parent NodeList. end() to return the parent NodeList.
			//
			// example:
			//		How to make a `dojo/NodeList` method that only returns the third node in
			//		the dojo/NodeList but allows access to the original NodeList by using this._stash:
			//	|	require(["dojo/query", "dojo/_base/lang", "dojo/NodeList", "dojo/NodeList-dom"
			//	|	], function(query, lang){
			//	|		lang.extend(NodeList, {
			//	|			third: function(){
			//	|				var newNodeList = NodeList(this[2]);
			//	|				return newNodeList._stash(this);
			//	|			}
			//	|		});
			//	|		// then see how _stash applies a sub-list, to be .end()'ed out of
			//	|		query(".foo")
			//	|			.third()
			//	|				.addClass("thirdFoo")
			//	|			.end()
			//	|			// access to the orig .foo list
			//	|			.removeClass("foo")
			//	|	});
			//
			this._parent = parent;
			return this; // dojo/NodeList
		},

		on: function(eventName, listener){
			// summary:
			//		Listen for events on the nodes in the NodeList. Basic usage is:
			//
			// example:
			//		|	require(["dojo/query"
			//		|	], function(query){
			//		|		query(".my-class").on("click", listener);
			//			This supports event delegation by using selectors as the first argument with the event names as
			//			pseudo selectors. For example:
			//		| 		query("#my-list").on("li:click", listener);
			//			This will listen for click events within `<li>` elements that are inside the `#my-list` element.
			//			Because on supports CSS selector syntax, we can use comma-delimited events as well:
			//		| 		query("#my-list").on("li button:mouseover, li:click", listener);
			//		|	});
			var handles = this.map(function(node){
				return on(node, eventName, listener); // TODO: apply to the NodeList so the same selector engine is used for matches
			});
			handles.remove = function(){
				for(var i = 0; i < handles.length; i++){
					handles[i].remove();
				}
			};
			return handles;
		},

		end: function(){
			// summary:
			//		Ends use of the current `NodeList` by returning the previous NodeList
			//		that generated the current NodeList.
			// description:
			//		Returns the `NodeList` that generated the current `NodeList`. If there
			//		is no parent NodeList, an empty NodeList is returned.
			// example:
			//	|	require(["dojo/query", "dojo/NodeList-dom"
			//	|	], function(query){
			//	|		query("a")
			//	|			.filter(".disabled")
			//	|				// operate on the anchors that only have a disabled class
			//	|				.style("color", "grey")
			//	|			.end()
			//	|			// jump back to the list of anchors
			//	|			.style(...)
			//	|	});
			//
			if(this._parent){
				return this._parent;
			}else{
				//Just return empty list.
				return new this._NodeListCtor(0);
			}
		},

		// http://developer.mozilla.org/en/docs/Core_JavaScript_1.5_Reference:Global_Objects:Array#Methods

		// FIXME: handle return values for #3244
		//		http://trac.dojotoolkit.org/ticket/3244

		// FIXME:
		//		need to wrap or implement:
		//			join (perhaps w/ innerHTML/outerHTML overload for toString() of items?)
		//			reduce
		//			reduceRight

		/*=====
		slice: function(begin, end){
			// summary:
			//		Returns a new NodeList, maintaining this one in place
			// description:
			//		This method behaves exactly like the Array.slice method
			//		with the caveat that it returns a `dojo/NodeList` and not a
			//		raw Array. For more details, see Mozilla's [slice
			//		documentation](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/slice)
			// begin: Integer
			//		Can be a positive or negative integer, with positive
			//		integers noting the offset to begin at, and negative
			//		integers denoting an offset from the end (i.e., to the left
			//		of the end)
			// end: Integer?
			//		Optional parameter to describe what position relative to
			//		the NodeList's zero index to end the slice at. Like begin,
			//		can be positive or negative.
			return this._wrap(a.slice.apply(this, arguments));
		},

		splice: function(index, howmany, item){
			// summary:
			//		Returns a new NodeList, manipulating this NodeList based on
			//		the arguments passed, potentially splicing in new elements
			//		at an offset, optionally deleting elements
			// description:
			//		This method behaves exactly like the Array.splice method
			//		with the caveat that it returns a `dojo/NodeList` and not a
			//		raw Array. For more details, see Mozilla's [splice
			//		documentation](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/splice)
			//		For backwards compatibility, calling .end() on the spliced NodeList
			//		does not return the original NodeList -- splice alters the NodeList in place.
			// index: Integer
			//		begin can be a positive or negative integer, with positive
			//		integers noting the offset to begin at, and negative
			//		integers denoting an offset from the end (i.e., to the left
			//		of the end)
			// howmany: Integer?
			//		Optional parameter to describe what position relative to
			//		the NodeList's zero index to end the slice at. Like begin,
			//		can be positive or negative.
			// item: Object...?
			//		Any number of optional parameters may be passed in to be
			//		spliced into the NodeList
			return this._wrap(a.splice.apply(this, arguments));	// dojo/NodeList
		},

		indexOf: function(value, fromIndex){
			// summary:
			//		see `dojo/_base/array.indexOf()`. The primary difference is that the acted-on
			//		array is implicitly this NodeList
			// value: Object
			//		The value to search for.
			// fromIndex: Integer?
			//		The location to start searching from. Optional. Defaults to 0.
			// description:
			//		For more details on the behavior of indexOf, see Mozilla's
			//		[indexOf
			//		docs](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/indexOf)
			// returns:
			//		Positive Integer or 0 for a match, -1 of not found.
			return d.indexOf(this, value, fromIndex); // Integer
		},

		lastIndexOf: function(value, fromIndex){
			// summary:
			//		see `dojo/_base/array.lastIndexOf()`. The primary difference is that the
			//		acted-on array is implicitly this NodeList
			// description:
			//		For more details on the behavior of lastIndexOf, see
			//		Mozilla's [lastIndexOf
			//		docs](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/lastIndexOf)
			// value: Object
			//		The value to search for.
			// fromIndex: Integer?
			//		The location to start searching from. Optional. Defaults to 0.
			// returns:
			//		Positive Integer or 0 for a match, -1 of not found.
			return d.lastIndexOf(this, value, fromIndex); // Integer
		},

		every: function(callback, thisObject){
			// summary:
			//		see `dojo/_base/array.every()` and the [Array.every
			//		docs](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/every).
			//		Takes the same structure of arguments and returns as
			//		dojo/_base/array.every() with the caveat that the passed array is
			//		implicitly this NodeList
			// callback: Function
			//		the callback
			// thisObject: Object?
			//		the context
			return d.every(this, callback, thisObject); // Boolean
		},

		some: function(callback, thisObject){
			// summary:
			//		Takes the same structure of arguments and returns as
			//		`dojo/_base/array.some()` with the caveat that the passed array is
			//		implicitly this NodeList.  See `dojo/_base/array.some()` and Mozilla's
			//		[Array.some
			//		documentation](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/some).
			// callback: Function
			//		the callback
			// thisObject: Object?
			//		the context
			return d.some(this, callback, thisObject); // Boolean
		},
		=====*/

		concat: function(item){
			// summary:
			//		Returns a new NodeList comprised of items in this NodeList
			//		as well as items passed in as parameters
			// description:
			//		This method behaves exactly like the Array.concat method
			//		with the caveat that it returns a `NodeList` and not a
			//		raw Array. For more details, see the [Array.concat
			//		docs](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/concat)
			// item: Object?
			//		Any number of optional parameters may be passed in to be
			//		spliced into the NodeList

			//return this._wrap(apc.apply(this, arguments));
			// the line above won't work for the native NodeList, or for Dojo NodeLists either :-(

			// implementation notes:
			// Array.concat() doesn't recognize native NodeLists or Dojo NodeLists
			// as arrays, and so does not inline them into a unioned array, but
			// appends them as single entities. Both the original NodeList and the
			// items passed in as parameters must be converted to raw Arrays
			// and then the concatenation result may be re-_wrap()ed as a Dojo NodeList.

			var t = aps.call(this, 0),
				m = array.map(arguments, function(a){
					return aps.call(a, 0);
				});
			return this._wrap(apc.apply(t, m), this);	// dojo/NodeList
		},

		map: function(/*Function*/ func, /*Function?*/ obj){
			// summary:
			//		see `dojo/_base/array.map()`. The primary difference is that the acted-on
			//		array is implicitly this NodeList and the return is a
			//		NodeList (a subclass of Array)
			return this._wrap(array.map(this, func, obj), this); // dojo/NodeList
		},

		forEach: function(callback, thisObj){
			// summary:
			//		see `dojo/_base/array.forEach()`. The primary difference is that the acted-on
			//		array is implicitly this NodeList. If you want the option to break out
			//		of the forEach loop, use every() or some() instead.
			forEach(this, callback, thisObj);
			// non-standard return to allow easier chaining
			return this; // dojo/NodeList
		},
		filter: function(/*String|Function*/ filter){
			// summary:
			//		"masks" the built-in javascript filter() method (supported
			//		in Dojo via `dojo/_base/array.filter`) to support passing a simple
			//		string filter in addition to supporting filtering function
			//		objects.
			// filter:
			//		If a string, a CSS rule like ".thinger" or "div > span".
			// example:
			//		"regular" JS filter syntax as exposed in `dojo/_base/array.filter`:
			//		|	require(["dojo/query", "dojo/NodeList-dom"
			//		|	], function(query){
			//		|		query("*").filter(function(item){
			//		|			// highlight every paragraph
			//		|			return (item.nodeName == "p");
			//		|		}).style("backgroundColor", "yellow");
			//		|	});
			// example:
			//		the same filtering using a CSS selector
			//		|	require(["dojo/query", "dojo/NodeList-dom"
			//		|	], function(query){
			//		|		query("*").filter("p").styles("backgroundColor", "yellow");
			//		|	});

			var a = arguments, items = this, start = 0;
			if(typeof filter == "string"){ // inline'd type check
				items = query._filterResult(this, a[0]);
				if(a.length == 1){
					// if we only got a string query, pass back the filtered results
					return items._stash(this); // dojo/NodeList
				}
				// if we got a callback, run it over the filtered items
				start = 1;
			}
			return this._wrap(array.filter(items, a[start], a[start + 1]), this);	// dojo/NodeList
		},
		instantiate: function(/*String|Object*/ declaredClass, /*Object?*/ properties){
			// summary:
			//		Create a new instance of a specified class, using the
			//		specified properties and each node in the NodeList as a
			//		srcNodeRef.
			// example:
			//		Grabs all buttons in the page and converts them to dijit/form/Button's.
			//	|	var buttons = query("button").instantiate(Button, {showLabel: true});
			var c = lang.isFunction(declaredClass) ? declaredClass : lang.getObject(declaredClass);
			properties = properties || {};
			return this.forEach(function(node){
				new c(properties, node);
			});	// dojo/NodeList
		},
		at: function(/*===== index =====*/){
			// summary:
			//		Returns a new NodeList comprised of items in this NodeList
			//		at the given index or indices.
			//
			// index: Integer...
			//		One or more 0-based indices of items in the current
			//		NodeList. A negative index will start at the end of the
			//		list and go backwards.
			//
			// example:
			//	Shorten the list to the first, second, and third elements
			//	|	require(["dojo/query"
			//	|	], function(query){
			//	|		query("a").at(0, 1, 2).forEach(fn);
			//	|	});
			//
			// example:
			//	Retrieve the first and last elements of a unordered list:
			//	|	require(["dojo/query"
			//	|	], function(query){
			//	|		query("ul > li").at(0, -1).forEach(cb);
			//	|	});
			//
			// example:
			//	Do something for the first element only, but end() out back to
			//	the original list and continue chaining:
			//	|	require(["dojo/query"
			//	|	], function(query){
			//	|		query("a").at(0).onclick(fn).end().forEach(function(n){
			//	|			console.log(n); // all anchors on the page.
			//	|	})
			//	|	});

			var t = new this._NodeListCtor(0);
			forEach(arguments, function(i){
				if(i < 0){ i = this.length + i; }
				if(this[i]){ t.push(this[i]); }
			}, this);
			return t._stash(this); // dojo/NodeList
		}
	});

	function queryForEngine(engine, NodeList){
		var query = function(/*String*/ query, /*String|DOMNode?*/ root){
			// summary:
			//		Returns nodes which match the given CSS selector, searching the
			//		entire document by default but optionally taking a node to scope
			//		the search by. Returns an instance of NodeList.
			if(typeof root == "string"){
				root = dom.byId(root);
				if(!root){
					return new NodeList([]);
				}
			}
			var results = typeof query == "string" ? engine(query, root) : query ? (query.end && query.on) ? query : [query] : [];
			if(results.end && results.on){
				// already wrapped
				return results;
			}
			return new NodeList(results);
		};
		query.matches = engine.match || function(node, selector, root){
			// summary:
			//		Test to see if a node matches a selector
			return query.filter([node], selector, root).length > 0;
		};
		// the engine provides a filtering function, use it to for matching
		query.filter = engine.filter || function(nodes, selector, root){
			// summary:
			//		Filters an array of nodes. Note that this does not guarantee to return a NodeList, just an array.
			return query(selector, root).filter(function(node){
				return array.indexOf(nodes, node) > -1;
			});
		};
		if(typeof engine != "function"){
			var search = engine.search;
			engine = function(selector, root){
				// Slick does it backwards (or everyone else does it backwards, probably the latter)
				return search(root || document, selector);
			};
		}
		return query;
	}
	var query = queryForEngine(defaultEngine, NodeList);
	/*=====
	query = function(selector, context){
		// summary:
		//		This modules provides DOM querying functionality. The module export is a function
		//		that can be used to query for DOM nodes by CSS selector and returns a NodeList
		//		representing the matching nodes.
		// selector: String
		//		A CSS selector to search for.
		// context: String|DomNode?
		//		An optional context to limit the searching scope. Only nodes under `context` will be
		//		scanned.
		// example:
		//		add an onclick handler to every submit button in the document
		//		which causes the form to be sent via Ajax instead:
		//	|	require(["dojo/query", "dojo/request", "dojo/dom-form", "dojo/dom-construct", "dojo/dom-style"
		//	|	], function(query, request, domForm, domConstruct, domStyle){
		//	|		query("input[type='submit']").on("click", function(e){
		//	|			e.preventDefault(); // prevent sending the form
		//	|			var btn = e.target;
		//	|			request.post("http://example.com/", {
		//	|				data: domForm.toObject(btn.form)
		//	|			}).then(function(response){
		//	|				// replace the form with the response
		//	|				domConstruct.create(div, {innerHTML: response}, btn.form, "after");
		//	|				domStyle.set(btn.form, "display", "none");
		//	|			});
		//	|		});
		//	|	});
		//
		// description:
		//		dojo/query is responsible for loading the appropriate query engine and wrapping
		//		its results with a `NodeList`. You can use dojo/query with a specific selector engine
		//		by using it as a plugin. For example, if you installed the sizzle package, you could
		//		use it as the selector engine with:
		//		|	require(["dojo/query!sizzle"], function(query){
		//		|		query("div")...
		//
		//		The id after the ! can be a module id of the selector engine or one of the following values:
		//
		//		- acme: This is the default engine used by Dojo base, and will ensure that the full
		//		Acme engine is always loaded.
		//
		//		- css2: If the browser has a native selector engine, this will be used, otherwise a
		//		very minimal lightweight selector engine will be loaded that can do simple CSS2 selectors
		//		(by #id, .class, tag, and [name=value] attributes, with standard child or descendant (>)
		//		operators) and nothing more.
		//
		//		- css2.1: If the browser has a native selector engine, this will be used, otherwise the
		//		full Acme engine will be loaded.
		//
		//		- css3: If the browser has a native selector engine with support for CSS3 pseudo
		//		selectors (most modern browsers except IE8), this will be used, otherwise the
		//		full Acme engine will be loaded.
		//
		//		- Or the module id of a selector engine can be used to explicitly choose the selector engine
		//
		//		For example, if you are using CSS3 pseudo selectors in module, you can specify that
		//		you will need support them with:
		//		|	require(["dojo/query!css3"], function(query){
		//		|		query('#t > h3:nth-child(odd)')...
		//
		//		You can also choose the selector engine/load configuration by setting the query-selector:
		//		For example:
		//		|	<script data-dojo-config="query-selector:'css3'" src="dojo.js"></script>
		//
		return new NodeList(); // dojo/NodeList
	 };
	 =====*/

	// the query that is returned from this module is slightly different than dojo.query,
	// because dojo.query has to maintain backwards compatibility with returning a
	// true array which has performance problems. The query returned from the module
	// does not use true arrays, but rather inherits from Array, making it much faster to
	// instantiate.
	dojo.query = queryForEngine(defaultEngine, function(array){
		// call it without the new operator to invoke the back-compat behavior that returns a true array
		return NodeList(array);	// dojo/NodeList
	});

	query.load = function(id, parentRequire, loaded){
		// summary:
		//		can be used as AMD plugin to conditionally load new query engine
		// example:
		//	|	require(["dojo/query!custom"], function(qsa){
		//	|		// loaded selector/custom.js as engine
		//	|		qsa("#foobar").forEach(...);
		//	|	});
		loader.load(id, parentRequire, function(engine){
			loaded(queryForEngine(engine, NodeList));
		});
	};

	dojo._filterQueryResult = query._filterResult = function(nodes, selector, root){
		return new NodeList(query.filter(nodes, selector, root));
	};
	dojo.NodeList = query.NodeList = NodeList;
	return query;
});

},
'dojo/_base/window':function(){
define(["./kernel", "./lang", "../sniff"], function(dojo, lang, has){
// module:
//		dojo/_base/window

var ret = {
	// summary:
	//		API to save/set/restore the global/document scope.

	global: dojo.global,
	/*=====
	 global: {
		 // summary:
		 //		Alias for the current window. 'global' can be modified
		 //		for temporary context shifting. See also withGlobal().
		 // description:
		 //		Use this rather than referring to 'window' to ensure your code runs
		 //		correctly in managed contexts.
	 },
	 =====*/

	doc: dojo.global["document"] || null,
	/*=====
	doc: {
		// summary:
		//		Alias for the current document. 'doc' can be modified
		//		for temporary context shifting. See also withDoc().
		// description:
		//		Use this rather than referring to 'window.document' to ensure your code runs
		//		correctly in managed contexts.
		// example:
		//	|	n.appendChild(dojo.doc.createElement('div'));
	},
	=====*/

	body: function(/*Document?*/ doc){
		// summary:
		//		Return the body element of the specified document or of dojo/_base/window::doc.
		// example:
		//	|	win.body().appendChild(dojo.doc.createElement('div'));

		// Note: document.body is not defined for a strict xhtml document
		// Would like to memoize this, but dojo.doc can change vi dojo.withDoc().
		doc = doc || dojo.doc;
		return doc.body || doc.getElementsByTagName("body")[0]; // Node
	},

	setContext: function(/*Object*/ globalObject, /*DocumentElement*/ globalDocument){
		// summary:
		//		changes the behavior of many core Dojo functions that deal with
		//		namespace and DOM lookup, changing them to work in a new global
		//		context (e.g., an iframe). The varibles dojo.global and dojo.doc
		//		are modified as a result of calling this function and the result of
		//		`dojo.body()` likewise differs.
		dojo.global = ret.global = globalObject;
		dojo.doc = ret.doc = globalDocument;
	},

	withGlobal: function(	/*Object*/ globalObject,
							/*Function*/ callback,
							/*Object?*/ thisObject,
							/*Array?*/ cbArguments){
		// summary:
		//		Invoke callback with globalObject as dojo.global and
		//		globalObject.document as dojo.doc.
		// description:
		//		Invoke callback with globalObject as dojo.global and
		//		globalObject.document as dojo.doc. If provided, globalObject
		//		will be executed in the context of object thisObject
		//		When callback() returns or throws an error, the dojo.global
		//		and dojo.doc will be restored to its previous state.

		var oldGlob = dojo.global;
		try{
			dojo.global = ret.global = globalObject;
			return ret.withDoc.call(null, globalObject.document, callback, thisObject, cbArguments);
		}finally{
			dojo.global = ret.global = oldGlob;
		}
	},

	withDoc: function(	/*DocumentElement*/ documentObject,
						/*Function*/ callback,
						/*Object?*/ thisObject,
						/*Array?*/ cbArguments){
		// summary:
		//		Invoke callback with documentObject as dojo/_base/window::doc.
		// description:
		//		Invoke callback with documentObject as dojo/_base/window::doc. If provided,
		//		callback will be executed in the context of object thisObject
		//		When callback() returns or throws an error, the dojo/_base/window::doc will
		//		be restored to its previous state.

		var oldDoc = ret.doc,
			oldQ = has("quirks"),
			oldIE = has("ie"), isIE, mode, pwin;

		try{
			dojo.doc = ret.doc = documentObject;
			// update dojo.isQuirks and the value of the has feature "quirks".
			// remove setting dojo.isQuirks and dojo.isIE for 2.0
			dojo.isQuirks = has.add("quirks", dojo.doc.compatMode == "BackCompat", true, true); // no need to check for QuirksMode which was Opera 7 only

			if(has("ie")){
				if((pwin = documentObject.parentWindow) && pwin.navigator){
					// re-run IE detection logic and update dojo.isIE / has("ie")
					// (the only time parentWindow/navigator wouldn't exist is if we were not
					// passed an actual legitimate document object)
					isIE = parseFloat(pwin.navigator.appVersion.split("MSIE ")[1]) || undefined;
					mode = documentObject.documentMode;
					if(mode && mode != 5 && Math.floor(isIE) != mode){
						isIE = mode;
					}
					dojo.isIE = has.add("ie", isIE, true, true);
				}
			}

			if(thisObject && typeof callback == "string"){
				callback = thisObject[callback];
			}

			return callback.apply(thisObject, cbArguments || []);
		}finally{
			dojo.doc = ret.doc = oldDoc;
			dojo.isQuirks = has.add("quirks", oldQ, true, true);
			dojo.isIE = has.add("ie", oldIE, true, true);
		}
	}
};

 1  && lang.mixin(dojo, ret);

return ret;

});

},
'dojo/dom':function(){
define(["./sniff", "./_base/window"],
		function(has, win){
	// module:
	//		dojo/dom

	// FIXME: need to add unit tests for all the semi-public methods

	if(has("ie") <= 7){
		try{
			document.execCommand("BackgroundImageCache", false, true);
		}catch(e){
			// sane browsers don't have cache "issues"
		}
	}

	// =============================
	// DOM Functions
	// =============================

	// the result object
	var dom = {
		// summary:
		//		This module defines the core dojo DOM API.
	};

	if(has("ie")){
		dom.byId = function(id, doc){
			if(typeof id != "string"){
				return id;
			}
			var _d = doc || win.doc, te = id && _d.getElementById(id);
			// attributes.id.value is better than just id in case the
			// user has a name=id inside a form
			if(te && (te.attributes.id.value == id || te.id == id)){
				return te;
			}else{
				var eles = _d.all[id];
				if(!eles || eles.nodeName){
					eles = [eles];
				}
				// if more than 1, choose first with the correct id
				var i = 0;
				while((te = eles[i++])){
					if((te.attributes && te.attributes.id && te.attributes.id.value == id) || te.id == id){
						return te;
					}
				}
			}
		};
	}else{
		dom.byId = function(id, doc){
			// inline'd type check.
			// be sure to return null per documentation, to match IE branch.
			return ((typeof id == "string") ? (doc || win.doc).getElementById(id) : id) || null; // DOMNode
		};
	}
	/*=====
	 dom.byId = function(id, doc){
		// summary:
		//		Returns DOM node with matching `id` attribute or falsy value (ex: null or undefined)
		//		if not found.  If `id` is a DomNode, this function is a no-op.
		//
		// id: String|DOMNode
		//		A string to match an HTML id attribute or a reference to a DOM Node
		//
		// doc: Document?
		//		Document to work in. Defaults to the current value of
		//		dojo/_base/window.doc.  Can be used to retrieve
		//		node references from other documents.
		//
		// example:
		//		Look up a node by ID:
		//	|	require(["dojo/dom"], function(dom){
		//	|		var n = dom.byId("foo");
		//	|	});
		//
		// example:
		//		Check if a node exists, and use it.
		//	|	require(["dojo/dom"], function(dom){
		//	|		var n = dom.byId("bar");
		//	|		if(n){ doStuff() ... }
		//	|	});
		//
		// example:
		//		Allow string or DomNode references to be passed to a custom function:
		//	|	require(["dojo/dom"], function(dom){
		//	|		var foo = function(nodeOrId){
		//	|			nodeOrId = dom.byId(nodeOrId);
		//	|			// ... more stuff
		//	|		}
		//	|	});
	 };
	 =====*/

	dom.isDescendant = function(/*DOMNode|String*/ node, /*DOMNode|String*/ ancestor){
		// summary:
		//		Returns true if node is a descendant of ancestor
		// node: DOMNode|String
		//		string id or node reference to test
		// ancestor: DOMNode|String
		//		string id or node reference of potential parent to test against
		//
		// example:
		//		Test is node id="bar" is a descendant of node id="foo"
		//	|	require(["dojo/dom"], function(dom){
		//	|		if(dom.isDescendant("bar", "foo")){ ... }
		//	|	});

		try{
			node = dom.byId(node);
			ancestor = dom.byId(ancestor);
			while(node){
				if(node == ancestor){
					return true; // Boolean
				}
				node = node.parentNode;
			}
		}catch(e){ /* squelch, return false */ }
		return false; // Boolean
	};


	// TODO: do we need setSelectable in the base?

	// Add feature test for user-select CSS property
	// (currently known to work in all but IE < 10 and Opera)
	// TODO: The user-select CSS property as of May 2014 is no longer part of
	// any CSS specification. In IE, -ms-user-select does not do the same thing
	// as the unselectable attribute on elements; namely, dijit Editor buttons
	// do not properly prevent the content of the editable content frame from
	// unblurring. As a result, the -ms- prefixed version is omitted here.
	has.add("css-user-select", function(global, doc, element){
		// Avoid exception when dom.js is loaded in non-browser environments
		if(!element){ return false; }
		
		var style = element.style;
		var prefixes = ["Khtml", "O", "Moz", "Webkit"],
			i = prefixes.length,
			name = "userSelect",
			prefix;

		// Iterate prefixes from most to least likely
		do{
			if(typeof style[name] !== "undefined"){
				// Supported; return property name
				return name;
			}
		}while(i-- && (name = prefixes[i] + "UserSelect"));

		// Not supported if we didn't return before now
		return false;
	});

	/*=====
	dom.setSelectable = function(node, selectable){
		// summary:
		//		Enable or disable selection on a node
		// node: DOMNode|String
		//		id or reference to node
		// selectable: Boolean
		//		state to put the node in. false indicates unselectable, true
		//		allows selection.
		// example:
		//		Make the node id="bar" unselectable
		//	|	require(["dojo/dom"], function(dom){
		//	|		dom.setSelectable("bar");
		//	|	});
		// example:
		//		Make the node id="bar" selectable
		//	|	require(["dojo/dom"], function(dom){
		//	|		dom.setSelectable("bar", true);
		//	|	});
	};
	=====*/

	var cssUserSelect = has("css-user-select");
	dom.setSelectable = cssUserSelect ? function(node, selectable){
		// css-user-select returns a (possibly vendor-prefixed) CSS property name
		dom.byId(node).style[cssUserSelect] = selectable ? "" : "none";
	} : function(node, selectable){
		node = dom.byId(node);

		// (IE < 10 / Opera) Fall back to setting/removing the
		// unselectable attribute on the element and all its children
		var nodes = node.getElementsByTagName("*"),
			i = nodes.length;

		if(selectable){
			node.removeAttribute("unselectable");
			while(i--){
				nodes[i].removeAttribute("unselectable");
			}
		}else{
			node.setAttribute("unselectable", "on");
			while(i--){
				nodes[i].setAttribute("unselectable", "on");
			}
		}
	};

	return dom;
});

},
'dojo/_base/kernel':function(){
define(["../has", "./config", "require", "module"], function(has, config, require, module){
	// module:
	//		dojo/_base/kernel

	// This module is the foundational module of the dojo boot sequence; it defines the dojo object.

	var
		// loop variables for this module
		i, p,

		// create dojo, dijit, and dojox
		// FIXME: in 2.0 remove dijit, dojox being created by dojo
		global = (function () { return this; })(),
		dijit = {},
		dojox = {},
		dojo = {
			// summary:
			//		This module is the foundational module of the dojo boot sequence; it defines the dojo object.

			// notice dojo takes ownership of the value of the config module
			config:config,
			global:global,
			dijit:dijit,
			dojox:dojox
		};


	// Configure the scope map. For a 100% AMD application, the scope map is not needed other than to provide
	// a _scopeName property for the dojo, dijit, and dojox root object so those packages can create
	// unique names in the global space.
	//
	// Built, legacy modules use the scope map to allow those modules to be expressed as if dojo, dijit, and dojox,
	// where global when in fact they are either global under different names or not global at all. In v1.6-, the
	// config variable "scopeMap" was used to map names as used within a module to global names. This has been
	// subsumed by the AMD map configuration variable which can relocate packages to different names. For backcompat,
	// only the "*" mapping is supported. See http://livedocs.dojotoolkit.org/developer/design/loader#legacy-cross-domain-mode for details.
	//
	// The following computations contort the packageMap for this dojo instance into a scopeMap.
	var scopeMap =
			// a map from a name used in a legacy module to the (global variable name, object addressed by that name)
			// always map dojo, dijit, and dojox
			{
				dojo:["dojo", dojo],
				dijit:["dijit", dijit],
				dojox:["dojox", dojox]
			},

		packageMap =
			// the package map for this dojo instance; note, a foreign loader or no pacakgeMap results in the above default config
			(require.map && require.map[module.id.match(/[^\/]+/)[0]]),

		item;


	// process all mapped top-level names for this instance of dojo
	for(p in packageMap){
		if(scopeMap[p]){
			// mapped dojo, dijit, or dojox
			scopeMap[p][0] = packageMap[p];
		}else{
			// some other top-level name
			scopeMap[p] = [packageMap[p], {}];
		}
	}

	// publish those names to _scopeName and, optionally, the global namespace
	for(p in scopeMap){
		item = scopeMap[p];
		item[1]._scopeName = item[0];
		if(!config.noGlobals){
			global[item[0]] = item[1];
		}
	}
	dojo.scopeMap = scopeMap;

	/*===== dojo.__docParserConfigureScopeMap(scopeMap); =====*/

	// FIXME: dojo.baseUrl and dojo.config.baseUrl should be deprecated
	dojo.baseUrl = dojo.config.baseUrl = require.baseUrl;
	dojo.isAsync = ! 1  || require.async;
	dojo.locale = config.locale;

	var rev = "$Rev: f4fef70 $".match(/[0-9a-f]{7,}/);
	dojo.version = {
		// summary:
		//		Version number of the Dojo Toolkit
		// description:
		//		Hash about the version, including
		//
		//		- major: Integer: Major version. If total version is "1.2.0beta1", will be 1
		//		- minor: Integer: Minor version. If total version is "1.2.0beta1", will be 2
		//		- patch: Integer: Patch version. If total version is "1.2.0beta1", will be 0
		//		- flag: String: Descriptor flag. If total version is "1.2.0beta1", will be "beta1"
		//		- revision: Number: The Git rev from which dojo was pulled

		major: 1, minor: 10, patch: 4, flag: "",
		revision: rev ? rev[0] : NaN,
		toString: function(){
			var v = dojo.version;
			return v.major + "." + v.minor + "." + v.patch + v.flag + " (" + v.revision + ")";	// String
		}
	};

	// If  1  is truthy, then as a dojo module is defined it should push it's definitions
	// into the dojo object, and conversely. In 2.0, it will likely be unusual to augment another object
	// as a result of defining a module. This has feature gives a way to force 2.0 behavior as the code
	// is migrated. Absent specific advice otherwise, set extend-dojo to truthy.
	 1 || has.add("extend-dojo", 1);


	(Function("d", "d.eval = function(){return d.global.eval ? d.global.eval(arguments[0]) : eval(arguments[0]);}"))(dojo);
	/*=====
	dojo.eval = function(scriptText){
		// summary:
		//		A legacy method created for use exclusively by internal Dojo methods. Do not use this method
		//		directly unless you understand its possibly-different implications on the platforms your are targeting.
		// description:
		//		Makes an attempt to evaluate scriptText in the global scope. The function works correctly for browsers
		//		that support indirect eval.
		//
		//		As usual, IE does not. On IE, the only way to implement global eval is to
		//		use execScript. Unfortunately, execScript does not return a value and breaks some current usages of dojo.eval.
		//		This implementation uses the technique of executing eval in the scope of a function that is a single scope
		//		frame below the global scope; thereby coming close to the global scope. Note carefully that
		//
		//		dojo.eval("var pi = 3.14;");
		//
		//		will define global pi in non-IE environments, but define pi only in a temporary local scope for IE. If you want
		//		to define a global variable using dojo.eval, write something like
		//
		//		dojo.eval("window.pi = 3.14;")
		// scriptText:
		//		The text to evaluation.
		// returns:
		//		The result of the evaluation. Often `undefined`
	};
	=====*/


	if( 0 ){
		dojo.exit = function(exitcode){
			quit(exitcode);
		};
	}else{
		dojo.exit = function(){
		};
	}

	 1 || has.add("dojo-guarantee-console",
		// ensure that console.log, console.warn, etc. are defined
		1
	);
	if( 1 ){
		typeof console != "undefined" || (console = {});
		//	Be careful to leave 'log' always at the end
		var cn = [
			"assert", "count", "debug", "dir", "dirxml", "error", "group",
			"groupEnd", "info", "profile", "profileEnd", "time", "timeEnd",
			"trace", "warn", "log"
		];
		var tn;
		i = 0;
		while((tn = cn[i++])){
			if(!console[tn]){
				(function(){
					var tcn = tn + "";
					console[tcn] = ('log' in console) ? function(){
						var a = Array.prototype.slice.call(arguments);
						a.unshift(tcn + ":");
						console["log"](a.join(" "));
					} : function(){};
					console[tcn]._fake = true;
				})();
			}
		}
	}

	 0 && has.add("dojo-debug-messages",
		// include dojo.deprecated/dojo.experimental implementations
		!!config.isDebug
	);
	dojo.deprecated = dojo.experimental =  function(){};
	if( 0 ){
		dojo.deprecated = function(/*String*/ behaviour, /*String?*/ extra, /*String?*/ removal){
			// summary:
			//		Log a debug message to indicate that a behavior has been
			//		deprecated.
			// behaviour: String
			//		The API or behavior being deprecated. Usually in the form
			//		of "myApp.someFunction()".
			// extra: String?
			//		Text to append to the message. Often provides advice on a
			//		new function or facility to achieve the same goal during
			//		the deprecation period.
			// removal: String?
			//		Text to indicate when in the future the behavior will be
			//		removed. Usually a version number.
			// example:
			//	| dojo.deprecated("myApp.getTemp()", "use myApp.getLocaleTemp() instead", "1.0");

			var message = "DEPRECATED: " + behaviour;
			if(extra){ message += " " + extra; }
			if(removal){ message += " -- will be removed in version: " + removal; }
			console.warn(message);
		};

		dojo.experimental = function(/* String */ moduleName, /* String? */ extra){
			// summary:
			//		Marks code as experimental.
			// description:
			//		This can be used to mark a function, file, or module as
			//		experimental.	 Experimental code is not ready to be used, and the
			//		APIs are subject to change without notice.	Experimental code may be
			//		completed deleted without going through the normal deprecation
			//		process.
			// moduleName: String
			//		The name of a module, or the name of a module file or a specific
			//		function
			// extra: String?
			//		some additional message for the user
			// example:
			//	| dojo.experimental("dojo.data.Result");
			// example:
			//	| dojo.experimental("dojo.weather.toKelvin()", "PENDING approval from NOAA");

			var message = "EXPERIMENTAL: " + moduleName + " -- APIs subject to change without notice.";
			if(extra){ message += " " + extra; }
			console.warn(message);
		};
	}

	 0 && has.add("dojo-modulePaths",
		// consume dojo.modulePaths processing
		1
	);
	if( 0 ){
		// notice that modulePaths won't be applied to any require's before the dojo/_base/kernel factory is run;
		// this is the v1.6- behavior.
		if(config.modulePaths){
			dojo.deprecated("dojo.modulePaths", "use paths configuration");
			var paths = {};
			for(p in config.modulePaths){
				paths[p.replace(/\./g, "/")] = config.modulePaths[p];
			}
			require({paths:paths});
		}
	}

	 0 && has.add("dojo-moduleUrl",
		// include dojo.moduleUrl
		1
	);
	if( 0 ){
		dojo.moduleUrl = function(/*String*/module, /*String?*/url){
			// summary:
			//		Returns a URL relative to a module.
			// example:
			//	|	var pngPath = dojo.moduleUrl("acme","images/small.png");
			//	|	console.dir(pngPath); // list the object properties
			//	|	// create an image and set it's source to pngPath's value:
			//	|	var img = document.createElement("img");
			//	|	img.src = pngPath;
			//	|	// add our image to the document
			//	|	dojo.body().appendChild(img);
			// example:
			//		you may de-reference as far as you like down the package
			//		hierarchy.  This is sometimes handy to avoid lengthy relative
			//		urls or for building portable sub-packages. In this example,
			//		the `acme.widget` and `acme.util` directories may be located
			//		under different roots (see `dojo.registerModulePath`) but the
			//		the modules which reference them can be unaware of their
			//		relative locations on the filesystem:
			//	|	// somewhere in a configuration block
			//	|	dojo.registerModulePath("acme.widget", "../../acme/widget");
			//	|	dojo.registerModulePath("acme.util", "../../util");
			//	|
			//	|	// ...
			//	|
			//	|	// code in a module using acme resources
			//	|	var tmpltPath = dojo.moduleUrl("acme.widget","templates/template.html");
			//	|	var dataPath = dojo.moduleUrl("acme.util","resources/data.json");

			dojo.deprecated("dojo.moduleUrl()", "use require.toUrl", "2.0");

			// require.toUrl requires a filetype; therefore, just append the suffix "/*.*" to guarantee a filetype, then
			// remove the suffix from the result. This way clients can request a url w/out a filetype. This should be
			// rare, but it maintains backcompat for the v1.x line (note: dojo.moduleUrl will be removed in v2.0).
			// Notice * is an illegal filename so it won't conflict with any real path map that may exist the paths config.
			var result = null;
			if(module){
				result = require.toUrl(module.replace(/\./g, "/") + (url ? ("/" + url) : "") + "/*.*").replace(/\/\*\.\*/, "") + (url ? "" : "/");
			}
			return result;
		};
	}

	dojo._hasResource = {}; // for backward compatibility with layers built with 1.6 tooling

	return dojo;
});

},
'dojo/_base/lang':function(){
define(["./kernel", "../has", "../sniff"], function(dojo, has){
	// module:
	//		dojo/_base/lang

	has.add("bug-for-in-skips-shadowed", function(){
		// if true, the for-in iterator skips object properties that exist in Object's prototype (IE 6 - ?)
		for(var i in {toString: 1}){
			return 0;
		}
		return 1;
	});

	// Helper methods
	var _extraNames =
			has("bug-for-in-skips-shadowed") ?
				"hasOwnProperty.valueOf.isPrototypeOf.propertyIsEnumerable.toLocaleString.toString.constructor".split(".") : [],

		_extraLen = _extraNames.length,

		getProp = function(/*Array*/parts, /*Boolean*/create, /*Object*/context){
			if(!context){
				if(parts[0] && dojo.scopeMap[parts[0]]) {
					// Voodoo code from the old days where "dojo" or "dijit" maps to some special object
					// rather than just window.dojo
					context = dojo.scopeMap[parts.shift()][1];
				}else{
					context = dojo.global;
				}
			}

			try{
				for(var i = 0; i < parts.length; i++){
					var p = parts[i];
					if(!(p in context)){
						if(create){
							context[p] = {};
						}else{
							return;		// return undefined
						}
					}
					context = context[p];
				}
				return context; // mixed
			}catch(e){
				// "p in context" throws an exception when context is a number, boolean, etc. rather than an object,
				// so in that corner case just return undefined (by having no return statement)
			}
		},

		opts = Object.prototype.toString,

		efficient = function(obj, offset, startWith){
			return (startWith||[]).concat(Array.prototype.slice.call(obj, offset||0));
		},

		_pattern = /\{([^\}]+)\}/g;

	// Module export
	var lang = {
		// summary:
		//		This module defines Javascript language extensions.

		// _extraNames: String[]
		//		Lists property names that must be explicitly processed during for-in iteration
		//		in environments that have has("bug-for-in-skips-shadowed") true.
		_extraNames:_extraNames,

		_mixin: function(dest, source, copyFunc){
			// summary:
			//		Copies/adds all properties of source to dest; returns dest.
			// dest: Object
			//		The object to which to copy/add all properties contained in source.
			// source: Object
			//		The object from which to draw all properties to copy into dest.
			// copyFunc: Function?
			//		The process used to copy/add a property in source; defaults to the Javascript assignment operator.
			// returns:
			//		dest, as modified
			// description:
			//		All properties, including functions (sometimes termed "methods"), excluding any non-standard extensions
			//		found in Object.prototype, are copied/added to dest. Copying/adding each particular property is
			//		delegated to copyFunc (if any); copyFunc defaults to the Javascript assignment operator if not provided.
			//		Notice that by default, _mixin executes a so-called "shallow copy" and aggregate types are copied/added by reference.
			var name, s, i, empty = {};
			for(name in source){
				// the (!(name in empty) || empty[name] !== s) condition avoids copying properties in "source"
				// inherited from Object.prototype.	 For example, if dest has a custom toString() method,
				// don't overwrite it with the toString() method that source inherited from Object.prototype
				s = source[name];
				if(!(name in dest) || (dest[name] !== s && (!(name in empty) || empty[name] !== s))){
					dest[name] = copyFunc ? copyFunc(s) : s;
				}
			}

			if(has("bug-for-in-skips-shadowed")){
				if(source){
					for(i = 0; i < _extraLen; ++i){
						name = _extraNames[i];
						s = source[name];
						if(!(name in dest) || (dest[name] !== s && (!(name in empty) || empty[name] !== s))){
							dest[name] = copyFunc ? copyFunc(s) : s;
						}
					}
				}
			}

			return dest; // Object
		},

		mixin: function(dest, sources){
			// summary:
			//		Copies/adds all properties of one or more sources to dest; returns dest.
			// dest: Object
			//		The object to which to copy/add all properties contained in source. If dest is falsy, then
			//		a new object is manufactured before copying/adding properties begins.
			// sources: Object...
			//		One of more objects from which to draw all properties to copy into dest. sources are processed
			//		left-to-right and if more than one of these objects contain the same property name, the right-most
			//		value "wins".
			// returns: Object
			//		dest, as modified
			// description:
			//		All properties, including functions (sometimes termed "methods"), excluding any non-standard extensions
			//		found in Object.prototype, are copied/added from sources to dest. sources are processed left to right.
			//		The Javascript assignment operator is used to copy/add each property; therefore, by default, mixin
			//		executes a so-called "shallow copy" and aggregate types are copied/added by reference.
			// example:
			//		make a shallow copy of an object
			//	|	var copy = lang.mixin({}, source);
			// example:
			//		many class constructors often take an object which specifies
			//		values to be configured on the object. In this case, it is
			//		often simplest to call `lang.mixin` on the `this` object:
			//	|	declare("acme.Base", null, {
			//	|		constructor: function(properties){
			//	|			// property configuration:
			//	|			lang.mixin(this, properties);
			//	|
			//	|			console.log(this.quip);
			//	|			//	...
			//	|		},
			//	|		quip: "I wasn't born yesterday, you know - I've seen movies.",
			//	|		// ...
			//	|	});
			//	|
			//	|	// create an instance of the class and configure it
			//	|	var b = new acme.Base({quip: "That's what it does!" });
			// example:
			//		copy in properties from multiple objects
			//	|	var flattened = lang.mixin(
			//	|		{
			//	|			name: "Frylock",
			//	|			braces: true
			//	|		},
			//	|		{
			//	|			name: "Carl Brutanananadilewski"
			//	|		}
			//	|	);
			//	|
			//	|	// will print "Carl Brutanananadilewski"
			//	|	console.log(flattened.name);
			//	|	// will print "true"
			//	|	console.log(flattened.braces);

			if(!dest){ dest = {}; }
			for(var i = 1, l = arguments.length; i < l; i++){
				lang._mixin(dest, arguments[i]);
			}
			return dest; // Object
		},

		setObject: function(name, value, context){
			// summary:
			//		Set a property from a dot-separated string, such as "A.B.C"
			// description:
			//		Useful for longer api chains where you have to test each object in
			//		the chain, or when you have an object reference in string format.
			//		Objects are created as needed along `path`. Returns the passed
			//		value if setting is successful or `undefined` if not.
			// name: String
			//		Path to a property, in the form "A.B.C".
			// value: anything
			//		value or object to place at location given by name
			// context: Object?
			//		Optional. Object to use as root of path. Defaults to
			//		`dojo.global`.
			// example:
			//		set the value of `foo.bar.baz`, regardless of whether
			//		intermediate objects already exist:
			//	| lang.setObject("foo.bar.baz", value);
			// example:
			//		without `lang.setObject`, we often see code like this:
			//	| // ensure that intermediate objects are available
			//	| if(!obj["parent"]){ obj.parent = {}; }
			//	| if(!obj.parent["child"]){ obj.parent.child = {}; }
			//	| // now we can safely set the property
			//	| obj.parent.child.prop = "some value";
			//		whereas with `lang.setObject`, we can shorten that to:
			//	| lang.setObject("parent.child.prop", "some value", obj);

			var parts = name.split("."), p = parts.pop(), obj = getProp(parts, true, context);
			return obj && p ? (obj[p] = value) : undefined; // Object
		},

		getObject: function(name, create, context){
			// summary:
			//		Get a property from a dot-separated string, such as "A.B.C"
			// description:
			//		Useful for longer api chains where you have to test each object in
			//		the chain, or when you have an object reference in string format.
			// name: String
			//		Path to an property, in the form "A.B.C".
			// create: Boolean?
			//		Optional. Defaults to `false`. If `true`, Objects will be
			//		created at any point along the 'path' that is undefined.
			// context: Object?
			//		Optional. Object to use as root of path. Defaults to
			//		'dojo.global'. Null may be passed.
			return getProp(name ? name.split(".") : [], create, context); // Object
		},

		exists: function(name, obj){
			// summary:
			//		determine if an object supports a given method
			// description:
			//		useful for longer api chains where you have to test each object in
			//		the chain. Useful for object and method detection.
			// name: String
			//		Path to an object, in the form "A.B.C".
			// obj: Object?
			//		Object to use as root of path. Defaults to
			//		'dojo.global'. Null may be passed.
			// example:
			//	| // define an object
			//	| var foo = {
			//	|		bar: { }
			//	| };
			//	|
			//	| // search the global scope
			//	| lang.exists("foo.bar"); // true
			//	| lang.exists("foo.bar.baz"); // false
			//	|
			//	| // search from a particular scope
			//	| lang.exists("bar", foo); // true
			//	| lang.exists("bar.baz", foo); // false
			return lang.getObject(name, false, obj) !== undefined; // Boolean
		},

		// Crockford (ish) functions

		isString: function(it){
			// summary:
			//		Return true if it is a String
			// it: anything
			//		Item to test.
			return (typeof it == "string" || it instanceof String); // Boolean
		},

		isArray: function(it){
			// summary:
			//		Return true if it is an Array.
			//		Does not work on Arrays created in other windows.
			// it: anything
			//		Item to test.
			return it && (it instanceof Array || typeof it == "array"); // Boolean
		},

		isFunction: function(it){
			// summary:
			//		Return true if it is a Function
			// it: anything
			//		Item to test.
			return opts.call(it) === "[object Function]";
		},

		isObject: function(it){
			// summary:
			//		Returns true if it is a JavaScript object (or an Array, a Function
			//		or null)
			// it: anything
			//		Item to test.
			return it !== undefined &&
				(it === null || typeof it == "object" || lang.isArray(it) || lang.isFunction(it)); // Boolean
		},

		isArrayLike: function(it){
			// summary:
			//		similar to isArray() but more permissive
			// it: anything
			//		Item to test.
			// returns:
			//		If it walks like a duck and quacks like a duck, return `true`
			// description:
			//		Doesn't strongly test for "arrayness".  Instead, settles for "isn't
			//		a string or number and has a length property". Arguments objects
			//		and DOM collections will return true when passed to
			//		isArrayLike(), but will return false when passed to
			//		isArray().
			return it && it !== undefined && // Boolean
				// keep out built-in constructors (Number, String, ...) which have length
				// properties
				!lang.isString(it) && !lang.isFunction(it) &&
				!(it.tagName && it.tagName.toLowerCase() == 'form') &&
				(lang.isArray(it) || isFinite(it.length));
		},

		isAlien: function(it){
			// summary:
			//		Returns true if it is a built-in function or some other kind of
			//		oddball that *should* report as a function but doesn't
			return it && !lang.isFunction(it) && /\{\s*\[native code\]\s*\}/.test(String(it)); // Boolean
		},

		extend: function(ctor, props){
			// summary:
			//		Adds all properties and methods of props to constructor's
			//		prototype, making them available to all instances created with
			//		constructor.
			// ctor: Object
			//		Target constructor to extend.
			// props: Object
			//		One or more objects to mix into ctor.prototype
			for(var i=1, l=arguments.length; i<l; i++){
				lang._mixin(ctor.prototype, arguments[i]);
			}
			return ctor; // Object
		},

		_hitchArgs: function(scope, method){
			var pre = lang._toArray(arguments, 2);
			var named = lang.isString(method);
			return function(){
				// arrayify arguments
				var args = lang._toArray(arguments);
				// locate our method
				var f = named ? (scope||dojo.global)[method] : method;
				// invoke with collected args
				return f && f.apply(scope || this, pre.concat(args)); // mixed
			}; // Function
		},

		hitch: function(scope, method){
			// summary:
			//		Returns a function that will only ever execute in the given scope.
			//		This allows for easy use of object member functions
			//		in callbacks and other places in which the "this" keyword may
			//		otherwise not reference the expected scope.
			//		Any number of default positional arguments may be passed as parameters
			//		beyond "method".
			//		Each of these values will be used to "placehold" (similar to curry)
			//		for the hitched function.
			// scope: Object
			//		The scope to use when method executes. If method is a string,
			//		scope is also the object containing method.
			// method: Function|String...
			//		A function to be hitched to scope, or the name of the method in
			//		scope to be hitched.
			// example:
			//	|	lang.hitch(foo, "bar")();
			//		runs foo.bar() in the scope of foo
			// example:
			//	|	lang.hitch(foo, myFunction);
			//		returns a function that runs myFunction in the scope of foo
			// example:
			//		Expansion on the default positional arguments passed along from
			//		hitch. Passed args are mixed first, additional args after.
			//	|	var foo = { bar: function(a, b, c){ console.log(a, b, c); } };
			//	|	var fn = lang.hitch(foo, "bar", 1, 2);
			//	|	fn(3); // logs "1, 2, 3"
			// example:
			//	|	var foo = { bar: 2 };
			//	|	lang.hitch(foo, function(){ this.bar = 10; })();
			//		execute an anonymous function in scope of foo
			if(arguments.length > 2){
				return lang._hitchArgs.apply(dojo, arguments); // Function
			}
			if(!method){
				method = scope;
				scope = null;
			}
			if(lang.isString(method)){
				scope = scope || dojo.global;
				if(!scope[method]){ throw(['lang.hitch: scope["', method, '"] is null (scope="', scope, '")'].join('')); }
				return function(){ return scope[method].apply(scope, arguments || []); }; // Function
			}
			return !scope ? method : function(){ return method.apply(scope, arguments || []); }; // Function
		},

		delegate: (function(){
			// boodman/crockford delegation w/ cornford optimization
			function TMP(){}
			return function(obj, props){
				TMP.prototype = obj;
				var tmp = new TMP();
				TMP.prototype = null;
				if(props){
					lang._mixin(tmp, props);
				}
				return tmp; // Object
			};
		})(),
		/*=====
		delegate: function(obj, props){
			// summary:
			//		Returns a new object which "looks" to obj for properties which it
			//		does not have a value for. Optionally takes a bag of properties to
			//		seed the returned object with initially.
			// description:
			//		This is a small implementation of the Boodman/Crockford delegation
			//		pattern in JavaScript. An intermediate object constructor mediates
			//		the prototype chain for the returned object, using it to delegate
			//		down to obj for property lookup when object-local lookup fails.
			//		This can be thought of similarly to ES4's "wrap", save that it does
			//		not act on types but rather on pure objects.
			// obj: Object
			//		The object to delegate to for properties not found directly on the
			//		return object or in props.
			// props: Object...
			//		an object containing properties to assign to the returned object
			// returns:
			//		an Object of anonymous type
			// example:
			//	|	var foo = { bar: "baz" };
			//	|	var thinger = lang.delegate(foo, { thud: "xyzzy"});
			//	|	thinger.bar == "baz"; // delegated to foo
			//	|	foo.thud == undefined; // by definition
			//	|	thinger.thud == "xyzzy"; // mixed in from props
			//	|	foo.bar = "thonk";
			//	|	thinger.bar == "thonk"; // still delegated to foo's bar
		},
		=====*/

		_toArray: has("ie") ?
			(function(){
				function slow(obj, offset, startWith){
					var arr = startWith||[];
					for(var x = offset || 0; x < obj.length; x++){
						arr.push(obj[x]);
					}
					return arr;
				}
				return function(obj){
					return ((obj.item) ? slow : efficient).apply(this, arguments);
				};
			})() : efficient,
		/*=====
		 _toArray: function(obj, offset, startWith){
			 // summary:
			 //		Converts an array-like object (i.e. arguments, DOMCollection) to an
			 //		array. Returns a new Array with the elements of obj.
			 // obj: Object
			 //		the object to "arrayify". We expect the object to have, at a
			 //		minimum, a length property which corresponds to integer-indexed
			 //		properties.
			 // offset: Number?
			 //		the location in obj to start iterating from. Defaults to 0.
			 //		Optional.
			 // startWith: Array?
			 //		An array to pack with the properties of obj. If provided,
			 //		properties in obj are appended at the end of startWith and
			 //		startWith is the returned array.
		 },
		 =====*/

		partial: function(/*Function|String*/ method /*, ...*/){
			// summary:
			//		similar to hitch() except that the scope object is left to be
			//		whatever the execution context eventually becomes.
			// description:
			//		Calling lang.partial is the functional equivalent of calling:
			//		|	lang.hitch(null, funcName, ...);
			// method:
			//		The function to "wrap"
			var arr = [ null ];
			return lang.hitch.apply(dojo, arr.concat(lang._toArray(arguments))); // Function
		},

		clone: function(/*anything*/ src){
			// summary:
			//		Clones objects (including DOM nodes) and all children.
			//		Warning: do not clone cyclic structures.
			// src:
			//		The object to clone
			if(!src || typeof src != "object" || lang.isFunction(src)){
				// null, undefined, any non-object, or function
				return src;	// anything
			}
			if(src.nodeType && "cloneNode" in src){
				// DOM Node
				return src.cloneNode(true); // Node
			}
			if(src instanceof Date){
				// Date
				return new Date(src.getTime());	// Date
			}
			if(src instanceof RegExp){
				// RegExp
				return new RegExp(src);   // RegExp
			}
			var r, i, l;
			if(lang.isArray(src)){
				// array
				r = [];
				for(i = 0, l = src.length; i < l; ++i){
					if(i in src){
						r.push(lang.clone(src[i]));
					}
				}
				// we don't clone functions for performance reasons
				//		}else if(d.isFunction(src)){
				//			// function
				//			r = function(){ return src.apply(this, arguments); };
			}else{
				// generic objects
				r = src.constructor ? new src.constructor() : {};
			}
			return lang._mixin(r, src, lang.clone);
		},


		trim: String.prototype.trim ?
			function(str){ return str.trim(); } :
			function(str){ return str.replace(/^\s\s*/, '').replace(/\s\s*$/, ''); },
		/*=====
		 trim: function(str){
			 // summary:
			 //		Trims whitespace from both sides of the string
			 // str: String
			 //		String to be trimmed
			 // returns: String
			 //		Returns the trimmed string
			 // description:
			 //		This version of trim() was selected for inclusion into the base due
			 //		to its compact size and relatively good performance
			 //		(see [Steven Levithan's blog](http://blog.stevenlevithan.com/archives/faster-trim-javascript)
			 //		Uses String.prototype.trim instead, if available.
			 //		The fastest but longest version of this function is located at
			 //		lang.string.trim()
		 },
		 =====*/

		replace: function(tmpl, map, pattern){
			// summary:
			//		Performs parameterized substitutions on a string. Throws an
			//		exception if any parameter is unmatched.
			// tmpl: String
			//		String to be used as a template.
			// map: Object|Function
			//		If an object, it is used as a dictionary to look up substitutions.
			//		If a function, it is called for every substitution with following parameters:
			//		a whole match, a name, an offset, and the whole template
			//		string (see https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Global_Objects/String/replace
			//		for more details).
			// pattern: RegEx?
			//		Optional regular expression objects that overrides the default pattern.
			//		Must be global and match one item. The default is: /\{([^\}]+)\}/g,
			//		which matches patterns like that: "{xxx}", where "xxx" is any sequence
			//		of characters, which doesn't include "}".
			// returns: String
			//		Returns the substituted string.
			// example:
			//	|	// uses a dictionary for substitutions:
			//	|	lang.replace("Hello, {name.first} {name.last} AKA {nick}!",
			//	|		{
			//	|			nick: "Bob",
			//	|			name: {
			//	|				first:	"Robert",
			//	|				middle: "X",
			//	|				last:		"Cringely"
			//	|			}
			//	|		});
			//	|	// returns: Hello, Robert Cringely AKA Bob!
			// example:
			//	|	// uses an array for substitutions:
			//	|	lang.replace("Hello, {0} {2}!",
			//	|		["Robert", "X", "Cringely"]);
			//	|	// returns: Hello, Robert Cringely!
			// example:
			//	|	// uses a function for substitutions:
			//	|	function sum(a){
			//	|		var t = 0;
			//	|		arrayforEach(a, function(x){ t += x; });
			//	|		return t;
			//	|	}
			//	|	lang.replace(
			//	|		"{count} payments averaging {avg} USD per payment.",
			//	|		lang.hitch(
			//	|			{ payments: [11, 16, 12] },
			//	|			function(_, key){
			//	|				switch(key){
			//	|					case "count": return this.payments.length;
			//	|					case "min":		return Math.min.apply(Math, this.payments);
			//	|					case "max":		return Math.max.apply(Math, this.payments);
			//	|					case "sum":		return sum(this.payments);
			//	|					case "avg":		return sum(this.payments) / this.payments.length;
			//	|				}
			//	|			}
			//	|		)
			//	|	);
			//	|	// prints: 3 payments averaging 13 USD per payment.
			// example:
			//	|	// uses an alternative PHP-like pattern for substitutions:
			//	|	lang.replace("Hello, ${0} ${2}!",
			//	|		["Robert", "X", "Cringely"], /\$\{([^\}]+)\}/g);
			//	|	// returns: Hello, Robert Cringely!

			return tmpl.replace(pattern || _pattern, lang.isFunction(map) ?
				map : function(_, k){ return lang.getObject(k, false, map); });
		}
	};

	 1  && lang.mixin(dojo, lang);

	return lang;
});


},
'dojo/_base/array':function(){
define(["./kernel", "../has", "./lang"], function(dojo, has, lang){
	// module:
	//		dojo/_base/array

	// our old simple function builder stuff
	var cache = {}, u;

	function buildFn(fn){
		return cache[fn] = new Function("item", "index", "array", fn); // Function
	}
	// magic snippet: if(typeof fn == "string") fn = cache[fn] || buildFn(fn);

	// every & some

	function everyOrSome(some){
		var every = !some;
		return function(a, fn, o){
			var i = 0, l = a && a.length || 0, result;
			if(l && typeof a == "string") a = a.split("");
			if(typeof fn == "string") fn = cache[fn] || buildFn(fn);
			if(o){
				for(; i < l; ++i){
					result = !fn.call(o, a[i], i, a);
					if(some ^ result){
						return !result;
					}
				}
			}else{
				for(; i < l; ++i){
					result = !fn(a[i], i, a);
					if(some ^ result){
						return !result;
					}
				}
			}
			return every; // Boolean
		};
	}

	// indexOf, lastIndexOf

	function index(up){
		var delta = 1, lOver = 0, uOver = 0;
		if(!up){
			delta = lOver = uOver = -1;
		}
		return function(a, x, from, last){
			if(last && delta > 0){
				// TODO: why do we use a non-standard signature? why do we need "last"?
				return array.lastIndexOf(a, x, from);
			}
			var l = a && a.length || 0, end = up ? l + uOver : lOver, i;
			if(from === u){
				i = up ? lOver : l + uOver;
			}else{
				if(from < 0){
					i = l + from;
					if(i < 0){
						i = lOver;
					}
				}else{
					i = from >= l ? l + uOver : from;
				}
			}
			if(l && typeof a == "string") a = a.split("");
			for(; i != end; i += delta){
				if(a[i] == x){
					return i; // Number
				}
			}
			return -1; // Number
		};
	}

	var array = {
		// summary:
		//		The Javascript v1.6 array extensions.

		every: everyOrSome(false),
		/*=====
		 every: function(arr, callback, thisObject){
			 // summary:
			 //		Determines whether or not every item in arr satisfies the
			 //		condition implemented by callback.
			 // arr: Array|String
			 //		the array to iterate on. If a string, operates on individual characters.
			 // callback: Function|String
			 //		a function is invoked with three arguments: item, index,
			 //		and array and returns true if the condition is met.
			 // thisObject: Object?
			 //		may be used to scope the call to callback
			 // returns: Boolean
			 // description:
			 //		This function corresponds to the JavaScript 1.6 Array.every() method, with one difference: when
			 //		run over sparse arrays, this implementation passes the "holes" in the sparse array to
			 //		the callback function with a value of undefined. JavaScript 1.6's every skips the holes in the sparse array.
			 //		For more details, see:
			 //		https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Objects/Array/every
			 // example:
			 //	|	// returns false
			 //	|	array.every([1, 2, 3, 4], function(item){ return item>1; });
			 // example:
			 //	|	// returns true
			 //	|	array.every([1, 2, 3, 4], function(item){ return item>0; });
		 },
		 =====*/

		some: everyOrSome(true),
		/*=====
		some: function(arr, callback, thisObject){
			// summary:
			//		Determines whether or not any item in arr satisfies the
			//		condition implemented by callback.
			// arr: Array|String
			//		the array to iterate over. If a string, operates on individual characters.
			// callback: Function|String
			//		a function is invoked with three arguments: item, index,
			//		and array and returns true if the condition is met.
			// thisObject: Object?
			//		may be used to scope the call to callback
			// returns: Boolean
			// description:
			//		This function corresponds to the JavaScript 1.6 Array.some() method, with one difference: when
			//		run over sparse arrays, this implementation passes the "holes" in the sparse array to
			//		the callback function with a value of undefined. JavaScript 1.6's some skips the holes in the sparse array.
			//		For more details, see:
			//		https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Objects/Array/some
			// example:
			//	| // is true
			//	| array.some([1, 2, 3, 4], function(item){ return item>1; });
			// example:
			//	| // is false
			//	| array.some([1, 2, 3, 4], function(item){ return item<1; });
		},
		=====*/

		indexOf: index(true),
		/*=====
		indexOf: function(arr, value, fromIndex, findLast){
			// summary:
			//		locates the first index of the provided value in the
			//		passed array. If the value is not found, -1 is returned.
			// description:
			//		This method corresponds to the JavaScript 1.6 Array.indexOf method, with two differences:
			//
			//		1. when run over sparse arrays, the Dojo function invokes the callback for every index
			//		   whereas JavaScript 1.6's indexOf skips the holes in the sparse array.
			//		2. uses equality (==) rather than strict equality (===)
			//
			//		For details on this method, see:
			//		https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Objects/Array/indexOf
			// arr: Array
			// value: Object
			// fromIndex: Integer?
			// findLast: Boolean?
			//		Makes indexOf() work like lastIndexOf().  Used internally; not meant for external usage.
			// returns: Number
		},
		=====*/

		lastIndexOf: index(false),
		/*=====
		lastIndexOf: function(arr, value, fromIndex){
			// summary:
			//		locates the last index of the provided value in the passed
			//		array. If the value is not found, -1 is returned.
			// description:
		 	//		This method corresponds to the JavaScript 1.6 Array.lastIndexOf method, with two differences:
		 	//
		 	//		1. when run over sparse arrays, the Dojo function invokes the callback for every index
		 	//		   whereas JavaScript 1.6's lasIndexOf skips the holes in the sparse array.
		 	//		2. uses equality (==) rather than strict equality (===)
		 	//
		 	//		For details on this method, see:
		 	//		https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Objects/Array/lastIndexOf
			// arr: Array,
			// value: Object,
			// fromIndex: Integer?
			// returns: Number
		},
		=====*/

		forEach: function(arr, callback, thisObject){
			// summary:
			//		for every item in arr, callback is invoked. Return values are ignored.
			//		If you want to break out of the loop, consider using array.every() or array.some().
			//		forEach does not allow breaking out of the loop over the items in arr.
			// arr:
			//		the array to iterate over. If a string, operates on individual characters.
			// callback:
			//		a function is invoked with three arguments: item, index, and array
			// thisObject:
			//		may be used to scope the call to callback
			// description:
			//		This function corresponds to the JavaScript 1.6 Array.forEach() method, with one difference: when
			//		run over sparse arrays, this implementation passes the "holes" in the sparse array to
			//		the callback function with a value of undefined. JavaScript 1.6's forEach skips the holes in the sparse array.
			//		For more details, see:
			//		https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Objects/Array/forEach
			// example:
			//	| // log out all members of the array:
			//	| array.forEach(
			//	|		[ "thinger", "blah", "howdy", 10 ],
			//	|		function(item){
			//	|			console.log(item);
			//	|		}
			//	| );
			// example:
			//	| // log out the members and their indexes
			//	| array.forEach(
			//	|		[ "thinger", "blah", "howdy", 10 ],
			//	|		function(item, idx, arr){
			//	|			console.log(item, "at index:", idx);
			//	|		}
			//	| );
			// example:
			//	| // use a scoped object member as the callback
			//	|
			//	| var obj = {
			//	|		prefix: "logged via obj.callback:",
			//	|		callback: function(item){
			//	|			console.log(this.prefix, item);
			//	|		}
			//	| };
			//	|
			//	| // specifying the scope function executes the callback in that scope
			//	| array.forEach(
			//	|		[ "thinger", "blah", "howdy", 10 ],
			//	|		obj.callback,
			//	|		obj
			//	| );
			//	|
			//	| // alternately, we can accomplish the same thing with lang.hitch()
			//	| array.forEach(
			//	|		[ "thinger", "blah", "howdy", 10 ],
			//	|		lang.hitch(obj, "callback")
			//	| );
			// arr: Array|String
			// callback: Function|String
			// thisObject: Object?

			var i = 0, l = arr && arr.length || 0;
			if(l && typeof arr == "string") arr = arr.split("");
			if(typeof callback == "string") callback = cache[callback] || buildFn(callback);
			if(thisObject){
				for(; i < l; ++i){
					callback.call(thisObject, arr[i], i, arr);
				}
			}else{
				for(; i < l; ++i){
					callback(arr[i], i, arr);
				}
			}
		},

		map: function(arr, callback, thisObject, Ctr){
			// summary:
			//		applies callback to each element of arr and returns
			//		an Array with the results
			// arr: Array|String
			//		the array to iterate on. If a string, operates on
			//		individual characters.
			// callback: Function|String
			//		a function is invoked with three arguments, (item, index,
			//		array),	 and returns a value
			// thisObject: Object?
			//		may be used to scope the call to callback
			// returns: Array
			// description:
			//		This function corresponds to the JavaScript 1.6 Array.map() method, with one difference: when
			//		run over sparse arrays, this implementation passes the "holes" in the sparse array to
			//		the callback function with a value of undefined. JavaScript 1.6's map skips the holes in the sparse array.
			//		For more details, see:
			//		https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Objects/Array/map
			// example:
			//	| // returns [2, 3, 4, 5]
			//	| array.map([1, 2, 3, 4], function(item){ return item+1 });

			// TODO: why do we have a non-standard signature here? do we need "Ctr"?
			var i = 0, l = arr && arr.length || 0, out = new (Ctr || Array)(l);
			if(l && typeof arr == "string") arr = arr.split("");
			if(typeof callback == "string") callback = cache[callback] || buildFn(callback);
			if(thisObject){
				for(; i < l; ++i){
					out[i] = callback.call(thisObject, arr[i], i, arr);
				}
			}else{
				for(; i < l; ++i){
					out[i] = callback(arr[i], i, arr);
				}
			}
			return out; // Array
		},

		filter: function(arr, callback, thisObject){
			// summary:
			//		Returns a new Array with those items from arr that match the
			//		condition implemented by callback.
			// arr: Array
			//		the array to iterate over.
			// callback: Function|String
			//		a function that is invoked with three arguments (item,
			//		index, array). The return of this function is expected to
			//		be a boolean which determines whether the passed-in item
			//		will be included in the returned array.
			// thisObject: Object?
			//		may be used to scope the call to callback
			// returns: Array
			// description:
			//		This function corresponds to the JavaScript 1.6 Array.filter() method, with one difference: when
			//		run over sparse arrays, this implementation passes the "holes" in the sparse array to
			//		the callback function with a value of undefined. JavaScript 1.6's filter skips the holes in the sparse array.
			//		For more details, see:
			//		https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Objects/Array/filter
			// example:
			//	| // returns [2, 3, 4]
			//	| array.filter([1, 2, 3, 4], function(item){ return item>1; });

			// TODO: do we need "Ctr" here like in map()?
			var i = 0, l = arr && arr.length || 0, out = [], value;
			if(l && typeof arr == "string") arr = arr.split("");
			if(typeof callback == "string") callback = cache[callback] || buildFn(callback);
			if(thisObject){
				for(; i < l; ++i){
					value = arr[i];
					if(callback.call(thisObject, value, i, arr)){
						out.push(value);
					}
				}
			}else{
				for(; i < l; ++i){
					value = arr[i];
					if(callback(value, i, arr)){
						out.push(value);
					}
				}
			}
			return out; // Array
		},

		clearCache: function(){
			cache = {};
		}
	};


	 1  && lang.mixin(dojo, array);

	return array;
});

},
'dojo/domReady':function(){
define(['./has'], function(has){
	var global = (function () { return this; })(),
		doc = document,
		readyStates = { 'loaded': 1, 'complete': 1 },
		fixReadyState = typeof doc.readyState != "string",
		ready = !!readyStates[doc.readyState],
		readyQ = [],
		recursiveGuard;

	function domReady(callback){
		// summary:
		//		Plugin to delay require()/define() callback from firing until the DOM has finished loading.
		readyQ.push(callback);
		if(ready){ processQ(); }
	}
	domReady.load = function(id, req, load){
		domReady(load);
	};

	// Export queue so that ready() can check if it's empty or not.
	domReady._Q = readyQ;
	domReady._onQEmpty = function(){
		// summary:
		//		Private method overridden by dojo/ready, to notify when everything in the
		//		domReady queue has been processed.  Do not use directly.
		//		Will be removed in 2.0, along with domReady._Q.
	};

	// For FF <= 3.5
	if(fixReadyState){ doc.readyState = "loading"; }

	function processQ(){
		// Calls all functions in the queue in order, unless processQ() is already running, in which case just return

		if(recursiveGuard){ return; }
		recursiveGuard = true;

		while(readyQ.length){
			try{
				(readyQ.shift())(doc);
			}catch(err){
				console.error(err, "in domReady callback", err.stack);
			}
		}

		recursiveGuard = false;

		// Notification for dojo/ready.  Remove for 2.0.
		// Note that this could add more tasks to the ready queue.
		domReady._onQEmpty();
	}

	if(!ready){
		var tests = [],
			detectReady = function(evt){
				evt = evt || global.event;
				if(ready || (evt.type == "readystatechange" && !readyStates[doc.readyState])){ return; }

				// For FF <= 3.5
				if(fixReadyState){ doc.readyState = "complete"; }

				ready = 1;
				processQ();
			},
			on = function(node, event){
				node.addEventListener(event, detectReady, false);
				readyQ.push(function(){ node.removeEventListener(event, detectReady, false); });
			};

		if(!has("dom-addeventlistener")){
			on = function(node, event){
				event = "on" + event;
				node.attachEvent(event, detectReady);
				readyQ.push(function(){ node.detachEvent(event, detectReady); });
			};

			var div = doc.createElement("div");
			try{
				if(div.doScroll && global.frameElement === null){
					// the doScroll test is only useful if we're in the top-most frame
					tests.push(function(){
						// Derived with permission from Diego Perini's IEContentLoaded
						// http://javascript.nwbox.com/IEContentLoaded/
						try{
							div.doScroll("left");
							return 1;
						}catch(e){}
					});
				}
			}catch(e){}
		}

		on(doc, "DOMContentLoaded");
		on(global, "load");

		if("onreadystatechange" in doc){
			on(doc, "readystatechange");
		}else if(!fixReadyState){
			// if the ready state property exists and there's
			// no readystatechange event, poll for the state
			// to change
			tests.push(function(){
				return readyStates[doc.readyState];
			});
		}

		if(tests.length){
			var poller = function(){
				if(ready){ return; }
				var i = tests.length;
				while(i--){
					if(tests[i]()){
						detectReady("poller");
						return;
					}
				}
				setTimeout(poller, 30);
			};
			poller();
		}
	}

	return domReady;
});

},
'dojo/_base/config':function(){
define(["../has", "require"], function(has, require){
	// module:
	//		dojo/_base/config

/*=====
return {
	// summary:
	//		This module defines the user configuration during bootstrap.
	// description:
	//		By defining user configuration as a module value, an entire configuration can be specified in a build,
	//		thereby eliminating the need for sniffing and or explicitly setting in the global variable dojoConfig.
	//		Also, when multiple instances of dojo exist in a single application, each will necessarily be located
	//		at an unique absolute module identifier as given by the package configuration. Implementing configuration
	//		as a module allows for specifying unique, per-instance configurations.
	// example:
	//		Create a second instance of dojo with a different, instance-unique configuration (assume the loader and
	//		dojo.js are already loaded).
	//		|	// specify a configuration that creates a new instance of dojo at the absolute module identifier "myDojo"
	//		|	require({
	//		|		packages:[{
	//		|			name:"myDojo",
	//		|			location:".", //assume baseUrl points to dojo.js
	//		|		}]
	//		|	});
	//		|
	//		|	// specify a configuration for the myDojo instance
	//		|	define("myDojo/config", {
	//		|		// normal configuration variables go here, e.g.,
	//		|		locale:"fr-ca"
	//		|	});
	//		|
	//		|	// load and use the new instance of dojo
	//		|	require(["myDojo"], function(dojo){
	//		|		// dojo is the new instance of dojo
	//		|		// use as required
	//		|	});

	// isDebug: Boolean
	//		Defaults to `false`. If set to `true`, ensures that Dojo provides
	//		extended debugging feedback via Firebug. If Firebug is not available
	//		on your platform, setting `isDebug` to `true` will force Dojo to
	//		pull in (and display) the version of Firebug Lite which is
	//		integrated into the Dojo distribution, thereby always providing a
	//		debugging/logging console when `isDebug` is enabled. Note that
	//		Firebug's `console.*` methods are ALWAYS defined by Dojo. If
	//		`isDebug` is false and you are on a platform without Firebug, these
	//		methods will be defined as no-ops.
	isDebug: false,

	// locale: String
	//		The locale to assume for loading localized resources in this page,
	//		specified according to [RFC 3066](http://www.ietf.org/rfc/rfc3066.txt).
	//		Must be specified entirely in lowercase, e.g. `en-us` and `zh-cn`.
	//		See the documentation for `dojo.i18n` and `dojo.requireLocalization`
	//		for details on loading localized resources. If no locale is specified,
	//		Dojo assumes the locale of the user agent, according to `navigator.userLanguage`
	//		or `navigator.language` properties.
	locale: undefined,

	// extraLocale: Array
	//		No default value. Specifies additional locales whose
	//		resources should also be loaded alongside the default locale when
	//		calls to `dojo.requireLocalization()` are processed.
	extraLocale: undefined,

	// baseUrl: String
	//		The directory in which `dojo.js` is located. Under normal
	//		conditions, Dojo auto-detects the correct location from which it
	//		was loaded. You may need to manually configure `baseUrl` in cases
	//		where you have renamed `dojo.js` or in which `<base>` tags confuse
	//		some browsers (e.g. IE 6). The variable `dojo.baseUrl` is assigned
	//		either the value of `djConfig.baseUrl` if one is provided or the
	//		auto-detected root if not. Other modules are located relative to
	//		this path. The path should end in a slash.
	baseUrl: undefined,

	// modulePaths: [deprecated] Object
	//		A map of module names to paths relative to `dojo.baseUrl`. The
	//		key/value pairs correspond directly to the arguments which
	//		`dojo.registerModulePath` accepts. Specifying
	//		`djConfig.modulePaths = { "foo": "../../bar" }` is the equivalent
	//		of calling `dojo.registerModulePath("foo", "../../bar");`. Multiple
	//		modules may be configured via `djConfig.modulePaths`.
	modulePaths: {},

	// addOnLoad: Function|Array
	//		Adds a callback via dojo/ready. Useful when Dojo is added after
	//		the page loads and djConfig.afterOnLoad is true. Supports the same
	//		arguments as dojo/ready. When using a function reference, use
	//		`djConfig.addOnLoad = function(){};`. For object with function name use
	//		`djConfig.addOnLoad = [myObject, "functionName"];` and for object with
	//		function reference use
	//		`djConfig.addOnLoad = [myObject, function(){}];`
	addOnLoad: null,

	// parseOnLoad: Boolean
	//		Run the parser after the page is loaded
	parseOnLoad: false,

	// require: String[]
	//		An array of module names to be loaded immediately after dojo.js has been included
	//		in a page.
	require: [],

	// defaultDuration: Number
	//		Default duration, in milliseconds, for wipe and fade animations within dijits.
	//		Assigned to dijit.defaultDuration.
	defaultDuration: 200,

	// dojoBlankHtmlUrl: String
	//		Used by some modules to configure an empty iframe. Used by dojo/io/iframe and
	//		dojo/back, and dijit/popup support in IE where an iframe is needed to make sure native
	//		controls do not bleed through the popups. Normally this configuration variable
	//		does not need to be set, except when using cross-domain/CDN Dojo builds.
	//		Save dojo/resources/blank.html to your domain and set `djConfig.dojoBlankHtmlUrl`
	//		to the path on your domain your copy of blank.html.
	dojoBlankHtmlUrl: undefined,

	// ioPublish: Boolean?
	//		Set this to true to enable publishing of topics for the different phases of
	//		IO operations. Publishing is done via dojo/topic.publish(). See dojo/main.__IoPublish for a list
	//		of topics that are published.
	ioPublish: false,

	// useCustomLogger: Anything?
	//		If set to a value that evaluates to true such as a string or array and
	//		isDebug is true and Firebug is not available or running, then it bypasses
	//		the creation of Firebug Lite allowing you to define your own console object.
	useCustomLogger: undefined,

	// transparentColor: Array
	//		Array containing the r, g, b components used as transparent color in dojo.Color;
	//		if undefined, [255,255,255] (white) will be used.
	transparentColor: undefined,
	
	// deps: Function|Array
	//		Defines dependencies to be used before the loader has been loaded.
	//		When provided, they cause the loader to execute require(deps, callback) 
	//		once it has finished loading. Should be used with callback.
	deps: undefined,
	
	// callback: Function|Array
	//		Defines a callback to be used when dependencies are defined before 
	//		the loader has been loaded. When provided, they cause the loader to 
	//		execute require(deps, callback) once it has finished loading. 
	//		Should be used with deps.
	callback: undefined,
	
	// deferredInstrumentation: Boolean
	//		Whether deferred instrumentation should be loaded or included
	//		in builds.
	deferredInstrumentation: true,

	// useDeferredInstrumentation: Boolean|String
	//		Whether the deferred instrumentation should be used.
	//
	//		* `"report-rejections"`: report each rejection as it occurs.
	//		* `true` or `1` or `"report-unhandled-rejections"`: wait 1 second
	//			in an attempt to detect unhandled rejections.
	useDeferredInstrumentation: "report-unhandled-rejections"
};
=====*/

	var result = {};
	if( 1 ){
		// must be the dojo loader; take a shallow copy of require.rawConfig
		var src = require.rawConfig, p;
		for(p in src){
			result[p] = src[p];
		}
	}else{
		var adviseHas = function(featureSet, prefix, booting){
			for(p in featureSet){
				p!="has" && has.add(prefix + p, featureSet[p], 0, booting);
			}
		};
		var global = (function () { return this; })();
		result =  1  ?
			// must be a built version of the dojo loader; all config stuffed in require.rawConfig
			require.rawConfig :
			// a foreign loader
			global.dojoConfig || global.djConfig || {};
		adviseHas(result, "config", 1);
		adviseHas(result.has, "", 1);
	}

	if(!result.locale && typeof navigator != "undefined"){
		// Default locale for browsers.
		var language = (navigator.language || navigator.userLanguage);
		if(language){
			result.locale = language.toLowerCase();
		}
	}

	return result;
});


}}});
(function(){
	// must use this.require to make this work in node.js
	var require = this.require;
	// consume the cached dojo layer
	require({cache:{}});
	!require.async && require(["dojo"]);
	require.boot && require.apply(null, require.boot);
})();
