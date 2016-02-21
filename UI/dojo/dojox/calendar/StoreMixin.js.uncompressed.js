define("dojox/calendar/StoreMixin", ["dojo/_base/declare", "dojo/_base/array", "dojo/_base/html", "dojo/_base/lang", "dojo/dom-class",
	"dojo/Stateful", "dojo/when"],
	function(declare, arr, html, lang, domClass, Stateful, when){

	return declare("dojox.calendar.StoreMixin", Stateful, {
		
		// summary:
		//		This mixin contains the store management.
		
		// store: dojo.store.Store
		//		The store that contains the events to display.
		store: null,
		
		// query: Object
		//		A query that can be passed to when querying the store.
		query: {},

		// queryOptions: dojo/store/api/Store.QueryOptions?
		//		Options to be applied when querying the store.
		queryOptions: null,

		// startTimeAttr: String
		//		The attribute of the store item that contains the start time of 
		//		the events represented by this item.	Default is "startTime". 
		startTimeAttr: "startTime",
		
		// endTimeAttr: String
		//		The attribute of the store item that contains the end time of 
		//		the events represented by this item.	Default is "endTime".
		endTimeAttr: "endTime",
		
		// summaryAttr: String
		//		The attribute of the store item that contains the summary of 
		//		the events represented by this item.	Default is "summary".
		summaryAttr: "summary",
		
		// allDayAttr: String
		//		The attribute of the store item that contains the all day state of 
		//		the events represented by this item.	Default is "allDay".
		allDayAttr: "allDay",
	
		// cssClassFunc: Function
		//		Optional function that returns a css class name to apply to item renderers that are displaying the specified item in parameter. 
		cssClassFunc: null,		
							
		// decodeDate: Function?
		//		An optional function to transform store date into Date objects.	Default is null. 
		decodeDate: null,
		
		// encodeDate: Function?
		//		An optional function to transform Date objects into store date.	Default is null. 
		encodeDate: null,
		
		// displayedItemsInvalidated: Boolean
		//		Whether the data items displayed must be recomputed, usually after the displayed 
		//		time range has changed. 
		// tags:
		//		protected
		displayedItemsInvalidated: false,
									
		itemToRenderItem: function(item, store){
			// summary:
			//		Creates the render item based on the dojo.store item. It must be of the form:
			//	|	{
			//  |		id: Object,
			//	|		startTime: Date,
			//	|		endTime: Date,
			//	|		summary: String
			//	|	}
			//		By default it is building an object using the store id, the summaryAttr, 
			//		startTimeAttr and endTimeAttr properties as well as decodeDate property if not null. 
			//		Other fields or way to query fields can be used if needed.
			// item: Object
			//		The store item. 
			// store: dojo.store.api.Store
			//		The store.
			// returns: Object
			if(this.owner){
				return this.owner.itemToRenderItem(item, store);
			}
			return {
				id: store.getIdentity(item),
				summary: item[this.summaryAttr],
				startTime: (this.decodeDate && this.decodeDate(item[this.startTimeAttr])) || this.newDate(item[this.startTimeAttr], this.dateClassObj),
				endTime: (this.decodeDate && this.decodeDate(item[this.endTimeAttr])) || this.newDate(item[this.endTimeAttr], this.dateClassObj),
				allDay: item[this.allDayAttr] != null ? item[this.allDayAttr] : false,
				cssClass: this.cssClassFunc ? this.cssClassFunc(item) : null 
			};
		},
		
		renderItemToItem: function(/*Object*/ renderItem, /*dojo.store.api.Store*/ store){
			// summary:
			//		Create a store item based on the render item. It must be of the form:
			//	|	{
			//	|		id: Object
			//	|		startTime: Date,
			//	|		endTime: Date,
			//	|		summary: String
			//	|	}
			//		By default it is building an object using the summaryAttr, startTimeAttr and endTimeAttr properties
			//		and encodeDate property if not null. If the encodeDate property is null a Date object will be set in the start and end time.
			//		When using a JsonRest store, for example, it is recommended to transfer dates using the ISO format (see dojo.date.stamp).
			//		In that case, provide a custom function to the encodeDate property that is using the date ISO encoding provided by Dojo. 
			// renderItem: Object
			//		The render item. 
			// store: dojo.store.api.Store
			//		The store.
			// returns:Object
			if(this.owner){
				return this.owner.renderItemToItem(renderItem, store);
			}
			var item = {};
			item[store.idProperty] = renderItem.id;
			item[this.summaryAttr] = renderItem.summary;
			item[this.startTimeAttr] = (this.encodeDate && this.encodeDate(renderItem.startTime)) || renderItem.startTime;
			item[this.endTimeAttr] = (this.encodeDate && this.encodeDate(renderItem.endTime)) || renderItem.endTime;
			return lang.mixin(store.get(renderItem.id), item);
		},			
		
		_computeVisibleItems: function(renderData){
			// summary:
			//		Computes the data items that are in the displayed interval.
			// renderData: Object
			//		The renderData that contains the start and end time of the displayed interval.
			// tags:
			//		protected

			var startTime = renderData.startTime;
			var endTime = renderData.endTime;
			if(this.items){
				renderData.items = arr.filter(this.items, function(item){
					return this.isOverlapping(renderData, item.startTime, item.endTime, startTime, endTime);
				}, this);
			}
		},
		
		_initItems: function(items){
			// tags:
			//		private
			this.set("items", items);
			return items;
		},
		
		_refreshItemsRendering: function(renderData){
		},
		
		_updateItems: function(object, previousIndex, newIndex){
			// as soon as we add a item or remove one layout might change,
			// let's make that the default
			// TODO: what about items in non visible area...
			// tags:
			//		private
			var layoutCanChange = true;
			var oldItem = null;
			var newItem = this.itemToRenderItem(object, this.store);
			// keep a reference on the store data item. 
			newItem._item = object;
			
			// set the item as in the store
			
			if(previousIndex!=-1){
				if(newIndex!=previousIndex){
					// this is a remove or a move
					this.items.splice(previousIndex, 1);
					if(this.setItemSelected && this.isItemSelected(newItem)){
						this.setItemSelected(newItem, false);
						this.dispatchChange(newItem, this.get("selectedItem"), null, null);
					}
				}else{
					// this is a put, previous and new index identical
					// check what changed
					oldItem = this.items[previousIndex];
					var cal = this.dateModule; 
					layoutCanChange = cal.compare(newItem.startTime, oldItem.startTime) != 0 ||
						cal.compare(newItem.endTime, oldItem.endTime) != 0;
					// we want to keep the same item object and mixin new values
					// into old object
					lang.mixin(oldItem, newItem); 
				}
			}else if(newIndex!=-1){
				// this is a add
				var s = this._getItemStoreStateObj(newItem);
				if(s){
					// if the item is at the correct index (creation)
					// we must fix it. Should not occur but ensure integrity.
					if(this.items[newIndex].id != newItem.id){						
						var l = this.items.length; 
						for(var i=l-1; i>=0; i--){
							if(this.items[i].id == newItem.id){
								this.items.splice(i, 1);
								break;
							}
						}						
						this.items.splice(newIndex, 0, newItem);						
					}
					// update with the latest values from the store.
					lang.mixin(s.renderItem, newItem);
				}else{
					this.items.splice(newIndex, 0, newItem);					
				}
				this.set("items", this.items);
			}	
			
			this._setItemStoreState(newItem, "stored");
			
			if(!this._isEditing){
				if(layoutCanChange){				
					this._refreshItemsRendering();			
				}else{
					// just update the item
					this.updateRenderers(oldItem);
				}
			}
		},
		
		_setStoreAttr: function(value){
			this.displayedItemsInvalidated = true;
			var r;

			if(this._observeHandler){
				this._observeHandler.remove();
				this._observeHandler = null;
			}
			if(value){				
				var results = value.query(this.query, this.queryOptions);
				if(results.observe){
					// user asked us to observe the store
					this._observeHandler = results.observe(lang.hitch(this, this._updateItems), true);
				}				
				results = results.map(lang.hitch(this, function(item){
					var renderItem = this.itemToRenderItem(item, value);
					// keep a reference on the store data item.
					renderItem._item = item;
					return renderItem;
				}));
				r = when(results, lang.hitch(this, this._initItems));
			}else{
				// we remove the store
				r = this._initItems([]);
			}
			this._set("store", value);
			return r;
		},
		
		_getItemStoreStateObj: function(/*Object*/item){
			// tags
			//		private
			
			if(this.owner){
				return this.owner._getItemStoreStateObj(item);
			}
			
			var store = this.get("store");
			if(store != null && this._itemStoreState != null){
				var id = item.id == undefined ? store.getIdentity(item) : item.id;
				return this._itemStoreState[id];
			}
			return null;
		},
		
		getItemStoreState: function(item){
			//	summary:
			//		Returns the creation state of an item. 
			//		This state is changing during the interactive creation of an item.
			//		Valid values are:
			//		- "unstored": The event is being interactively created. It is not in the store yet.
			//		- "storing": The creation gesture has ended, the event is being added to the store.
			//		- "stored": The event is not in the two previous states, and is assumed to be in the store 
			//		(not checking because of performance reasons, use store API for testing existence in store).
			// item: Object
			//		The item.
			// returns: String
			
			if(this.owner){
				return this.owner.getItemStoreState(item);
			}

			if(this._itemStoreState == null){
				return "stored";
			}
			
			var store = this.get("store");
			var id = item.id == undefined ? store.getIdentity(item) : item.id;
			var s = this._itemStoreState[id];
			
			if(store != null && s != undefined){				
				return s.state;								
			}
			return "stored";		
		},
		
		_setItemStoreState: function(/*Object*/item, /*String*/state){
			// tags
			//		private
			
			if(this.owner){
				this.owner._setItemStoreState(item, state);
				return;
			}
			
			if(this._itemStoreState == undefined){
				this._itemStoreState = {};
			}
			
			var store = this.get("store");
			var id = item.id == undefined ? store.getIdentity(item) : item.id;
			var s = this._itemStoreState[id];
			
						
			if(state == "stored" || state == null){
				if(s != undefined){
					delete this._itemStoreState[id];					
				}
				return;	
			}

			if(store){				
				this._itemStoreState[id] = {
						id: id,
						item: item,
						renderItem: this.itemToRenderItem(item, store),
						state: state
				};						
			}
		}
				
	});

});
