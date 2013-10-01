define("dijit/RadioMenuItem", [
	"dojo/_base/declare", // declare
	"dojo/dom-class", // domClass.toggle
	"./CheckedMenuItem"
], function(declare, domClass, CheckedMenuItem){

	// module:
	//		dijit/RadioButtonMenuItem

	return declare("dijit.RadioButtonMenuItem", CheckedMenuItem, {
		// summary:
		//		A radio-button-like menu item for toggling on and off

		baseClass: "dijitRadioMenuItem",

		role: "menuitemradio",

		// checkedChar: String
		//		Character (or string) used in place of radio button icon when display in high contrast mode
		checkedChar: "*",

		// group: String
		//		Toggling on a RadioMenuItem in a given group toggles off the other RadioMenuItems in that group.
		group: "",

		// mapping from group name to checked widget within that group (or null if no widget is checked)
		_currentlyChecked: {},

		_setCheckedAttr: function(/*Boolean*/ checked){
			// summary:
			//		Hook so attr('checked', bool) works.
			//		Sets the class and state for the check box.

			if(checked && this.group && this._currentlyChecked[this.group] && this._currentlyChecked[this.group] != this){
				// if another RadioMenuItem in my group is checked, uncheck it
				this._currentlyChecked[this.group].set("checked", false);
			}

			this.inherited(arguments);

			// set the currently checked widget to this, or null if we are clearing the currently checked widget
			if(this.group){
				if(checked){
					this._currentlyChecked[this.group] = this;
				}else if(this._currentlyChecked[this.group] == this){
					this._currentlyChecked[this.group] = null;
				}
			}
		},

		_onClick: function(evt){
			// summary:
			//		Clicking this item toggles it on.   If it's already on, then clicking does nothing.
			// tags:
			//		private

			if(!this.disabled && !this.checked){
				this.set("checked", true);
				this.onChange(true);
			}
			this.onClick(evt);
		}
	});
});
