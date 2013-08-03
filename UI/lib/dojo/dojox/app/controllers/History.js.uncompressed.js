define("dojox/app/controllers/History", ["dojo/_base/lang", "dojo/_base/declare", "dojo/on", "../Controller", "../utils/hash"],
function(lang, declare, on, Controller, hash){
	// module:
	//		dojox/app/controllers/History
	// summary:
	//		Bind "app-domNode" event on dojox/app application instance,
	//		Bind "startTransition" event on dojox/app application domNode,
	//		Bind "popstate" event on window object.
	//		Maintain history by HTML5 "pushState" method and "popstate" event.

	return declare("dojox.app.controllers.History", Controller, {
		constructor: function(app){
			// summary:
			//		Bind "app-domNode" event on dojox/app application instance,
			//		Bind "startTransition" event on dojox/app application domNode,
			//		Bind "popstate" event on window object.
			//
			// app:
			//		dojox/app application instance.

			this.events = {
				"app-domNode": this.onDomNodeChange
			};
			if(this.app.domNode){
				this.onDomNodeChange({oldNode: null, newNode: this.app.domNode});
			}
			this.bind(window, "popstate", lang.hitch(this, this.onPopState));
		},

		onDomNodeChange: function(evt){
			if(evt.oldNode != null){
				this.unbind(evt.oldNode, "startTransition");
			}
			this.bind(evt.newNode, "startTransition", lang.hitch(this, this.onStartTransition));
		},

		onStartTransition: function(evt){
			// summary:
			//		Response to dojox/app "startTransition" event.
			//
			// example:
			//		Use "dojox/mobile/TransitionEvent" to trigger "startTransition" event, and this function will response the event. For example:
			//		|	var transOpts = {
			//		|		title:"List",
			//		|		target:"items,list",
			//		|		url: "#items,list",
			//		|		params: {"param1":"p1value"}
			//		|	};
			//		|	new TransitionEvent(domNode, transOpts, e).dispatch();
			//
			// evt: Object
			//		transition options parameter
			
			// create url hash from target if it is not set
			var currentHash = evt.detail.url || "#"+evt.detail.target;
			if(evt.detail.params){
				currentHash = hash.buildWithParams(currentHash, evt.detail.params);
			}
			// push states to history list
			history.pushState(evt.detail, evt.detail.href, currentHash);
		},

		onPopState: function(evt){
			// summary:
			//		Response to dojox/app "popstate" event.
			//
			// evt: Object
			//		transition options parameter

			// Clean browser's cache and refresh the current page will trigger popState event,
			// but in this situation the application has not started and throws an error.
			// so we need to check application status, if application not STARTED, do nothing.
			if(this.app.getStatus() !== this.app.lifecycle.STARTED){
				return;
			}

			var state = evt.state;
			if(!state){
				if(window.location.hash){
					state = {
						target: hash.getTarget(location.hash),
						url: location.hash,
						params: hash.getParams(location.hash)
					}
				}else{
					state = {
						target: this.app.defaultView
					};
				}
			}

			// TODO explain what is the purpose of this, _sim is never set in dojox/app
			if(evt._sim){
				history.replaceState(state, state.title, state.href);
			}

			// transition to the target view
			this.app.emit("app-transition", {
				viewId: state.target,
				opts: lang.mixin({reverse: true}, evt.detail, {"params": state.params})
			});
		}
	});
});
