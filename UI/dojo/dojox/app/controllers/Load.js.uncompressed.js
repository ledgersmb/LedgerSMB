define("dojox/app/controllers/Load", ["require", "dojo/_base/lang", "dojo/_base/declare", "dojo/on", "dojo/Deferred", "dojo/when", "../Controller"],
	function(require, lang, declare, on, Deferred, when, Controller, View){
	// module:
	//		dojox/app/controllers/Load
	// summary:
	//		Bind "app-load" event on dojox/app application instance.
	//		Load child view and sub children at one time.

	return declare("dojox.app.controllers.Load", Controller, {


		_waitingQueue:[],

		constructor: function(app, events){
			// summary:
			//		bind "app-load" event on application instance.
			//
			// app:
			//		dojox/app application instance.
			// events:
			//		{event : handler}
			this.events = {
				"app-init": this.init,
				"app-load": this.load
			};
		},

		init: function(event){
			// when the load controller received "app-init", before the lifecycle really starts we create the root view
			// if any. This used to be done in main.js but must be done in Load to be able to create custom
			// views from the Load controller.
			//create and start child. return Deferred
			when(this.createView(event.parent, null, null, {
					templateString: event.templateString,
					controller: event.controller
			}, null, event.type), function(newView){
				when(newView.start(), event.callback);
			});
		},

		load: function(event){
			// summary:
			//		Response to dojox/app "loadArray" event.
			//
			// example:
			//		Use trigger() to trigger "loadArray" event, and this function will response the event. For example:
			//		|	this.trigger("app-load", {"parent":parent, "viewId":viewId, "viewArray":viewArray, "callback":function(){...}});
			//
			// event: Object
			//		LoadArray event parameter. It should be like this: {"parent":parent, "viewId":viewId, "viewArray":viewArray, "callback":function(){...}}
			// returns:
			//		A dojo/Deferred object.
			//		The return value cannot return directly. 
			//		If the caller need to use the return value, pass callback function in event parameter and process return value in callback function.

			this.app.log("in app/controllers/Load event.viewId="+event.viewId+" event =", event);
			var views = event.viewId || "";
			var viewArray = [];
			// create an array from the diff views in event.viewId (they are separated by +)
			var parts = views.split('+');
			while(parts.length > 0){ 	
				var viewId = parts.shift();
				viewArray.push(viewId);
			}

			var def;
			this.proceedLoadViewDef = new Deferred();
			if(viewArray && viewArray.length > 1){
				// loop thru the array calling loadView for each item in the array
				for(var i = 0; i < viewArray.length-1; i++){
					var newEvent = lang.clone(event);
					newEvent.callback = null;	// skip callback until after last view is loaded.
					newEvent.viewId = viewArray[i];
					this._waitingQueue.push(newEvent);
				}
				this.proceedLoadView(this._waitingQueue.shift());
				when(this.proceedLoadViewDef, lang.hitch(this, function(){
					// for last view leave the callback to be notified
					var newEvent = lang.clone(event);
					newEvent.viewId = viewArray[i];
					def = this.loadView(newEvent);
					return def;
				}));
			}else{
				def = this.loadView(event);
				return def;
			}
		},
		
		proceedLoadView: function(loadEvt){
			// summary:
			//		Proceed load queue by FIFO by default.
			//		If load is in proceeding, add the next load to waiting queue.
			//
			// loadEvt: Object
			//		LoadArray event parameter. It should be like this: {"parent":parent, "viewId":viewId, "viewArray":viewArray, "callback":function(){...}}

			var def = this.loadView(loadEvt);
			when(def, lang.hitch(this, function(){
						this.app.log("in app/controllers/Load proceedLoadView back from loadView for event", loadEvt);
						var nextEvt = this._waitingQueue.shift();
						if(nextEvt){
							this.app.log("in app/controllers/Load proceedLoadView back from loadView calling this.proceedLoadView(nextEvt) for ",nextEvt);
							this.proceedLoadView(nextEvt);
						}else{
							this._waitingQueue = [];
							this.proceedLoadViewDef.resolve();
						}
			}));
		},

		loadView: function(event){
			// summary:
			//		Response to dojox/app "app-load" event.
			//
			// example:
			//		Use trigger() to trigger "app-load" event, and this function will response the event. For example:
			//		|	this.trigger("app-load", {"parent":parent, "viewId":viewId, "callback":function(){...}});
			//
			// event: Object
			//		Load event parameter. It should be like this: {"parent":parent, "viewId":viewId, "callback":function(){...}}
			// returns:
			//		A dojo/Deferred object.
			//		The return value cannot return directly. 
			//		If the caller need to use the return value, pass callback function in event parameter and process return value in callback function.

			var parent = event.parent || this.app;
			var viewId = event.viewId || "";
			var parts = viewId.split(',');
			var childId = parts.shift();
			var subIds = parts.join(",");
			var params = event.params || "";

			var def = this.loadChild(parent, childId, subIds, params);
			// call Load event callback
			if(event.callback){
				when(def, event.callback);
			}
			return def;
		},

		createChild: function(parent, childId, subIds, params){
			// summary:
			//		Create a view instance if not already loaded by calling createView. This is typically a
			//		dojox/app/View.
			//
			// parent: Object
			//		parent of the view.
			// childId: String
			//		view id need to be loaded.
			// subIds: String
			//		sub views' id of this view.
			// returns:
			//		If view exist, return the view object.
			//		Otherwise, create the view and return a dojo.Deferred instance.

			var id = parent.id + '_' + childId;
			
			// check for possible default params if no params were provided
			if(!params && parent.views[childId].defaultParams){
				params = parent.views[childId].defaultParams;
			}
			var view = parent.children[id];
			if(view){
				// set params to new value before returning
				if(params){
					view.params = params;
				}
				this.app.log("in app/controllers/Load createChild view is already loaded so return the loaded view with the new parms ",view);
				return view;
			}
			var def = new Deferred();
			// create and start child. return Deferred
			when(this.createView(parent, id, childId, null, params, parent.views[childId].type), function(newView){
				parent.children[id] = newView;
				when(newView.start(), function(view){
					def.resolve(view);
				});
			});
			return def;
		},

		createView: function(parent, id, name, mixin, params, type){
			// summary:
			//		Create a dojox/app/View instance. Can be overridden to create different type of views.
			// parent: Object
			//		parent of this view.
			// id: String
			//		view id.
			// name: String
			//		view name.
			// mixin: String
			//		additional property to be mixed into the view (templateString, controller...)
			// params: Object
			//		params of this view.
			// type: String
			//		the MID of the View. If not provided "dojox/app/View".
			// returns:
			//		A dojo/Deferred instance which will be resolved when the view will be instantiated.
			// tags:
			//		protected
			var def = new Deferred();
			var app = this.app;
			require([type?type:"../View"], function(View){
				var newView = new View(lang.mixin({
					"app": app,
					"id": id,
					"name": name,
					"parent": parent
				}, { "params": params }, mixin));
				def.resolve(newView);
			});
			return def;
		},

		loadChild: function(parent, childId, subIds, params){
			// summary:
			//		Load child and sub children views recursively.
			//
			// parent: Object
			//		parent of this view.
			// childId: String
			//		view id need to be loaded.
			// subIds: String
			//		sub views' id of this view.
			// params: Object
			//		params of this view.
			// returns:
			//		A dojo/Deferred instance which will be resolved when all views loaded.

			//TODO: Can this be called with a viewId or default view which includes multiple views with a "+"?  Need to handle that!

			if(!parent){
				throw Error("No parent for Child '" + childId + "'.");
			}

			if(!childId){
				var parts = parent.defaultView ? parent.defaultView.split(",") : "default";
				childId = parts.shift();
				subIds = parts.join(',');
			}

			var loadChildDeferred = new Deferred();
			var createPromise;
			try{
				createPromise = this.createChild(parent, childId, subIds, params);
			}catch(ex){
				loadChildDeferred.reject("load child '"+childId+"' error.");
				return loadChildDeferred.promise;
			}
			when(createPromise, lang.hitch(this, function(child){
				// if no subIds and current view has default view, load the default view.
				if(!subIds && child.defaultView){
					subIds = child.defaultView;
				}

				var parts = subIds.split(',');
				childId = parts.shift();
				subIds = parts.join(',');
				if(childId){
					var subLoadDeferred = this.loadChild(child, childId, subIds, params);
					when(subLoadDeferred, function(){
						loadChildDeferred.resolve();
					},
					function(){
						loadChildDeferred.reject("load child '"+childId+"' error.");
					});
				}else{
					loadChildDeferred.resolve();
				}
			}),
			function(){
				loadChildDeferred.reject("load child '"+childId+"' error.")
			});
			return loadChildDeferred.promise; // dojo/Deferred.promise
		}
	});
});
