define("dijit/DropDownMenu", [
	"dojo/_base/declare", // declare
	"dojo/keys", // keys
	"dojo/text!./templates/Menu.html",
	"./_OnDijitClickMixin",
	"./_MenuBase"
], function(declare, keys, template, _OnDijitClickMixin, _MenuBase){

	// module:
	//		dijit/DropDownMenu

	return declare("dijit.DropDownMenu", [_MenuBase, _OnDijitClickMixin], {
		// summary:
		//		A menu, without features for context menu (Meaning, drop down menu)

		templateString: template,

		baseClass: "dijitMenu",

		// Arrow key navigation
		_onUpArrow: function(){
			this.focusPrev();
		},
		_onDownArrow: function(){
			this.focusNext();
		},
		_onRightArrow: function(/*Event*/ evt){
			this._moveToPopup(evt);
			evt.stopPropagation();
			evt.preventDefault();
		},
		_onLeftArrow: function(){
			if(this.parentMenu){
				if(this.parentMenu._isMenuBar){
					this.parentMenu.focusPrev();
				}else{
					this.onCancel(false);
				}
			}else{
				evt.stopPropagation();
				evt.preventDefault();
			}
		}
	});
});
require({cache:{
'url:dijit/templates/Menu.html':"<table class=\"dijit dijitMenu dijitMenuPassive dijitReset dijitMenuTable\" role=\"menu\" tabIndex=\"${tabIndex}\"\n\t   cellspacing=\"0\">\n\t<tbody class=\"dijitReset\" data-dojo-attach-point=\"containerNode\"></tbody>\n</table>\n"}});
