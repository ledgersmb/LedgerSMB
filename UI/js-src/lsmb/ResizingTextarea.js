define([
    "dijit/form/TextBox",
    "dojo/_base/declare",
    "dojo/debounce",
    "dojo/text!./templates/ResizingTextarea.html"
    ], function(
        TextBox,
        declare,
        debounce,
        template
      ){
        return declare("lsmb/ResizingTextarea",
                       [TextBox], {
            innerStyle: "",
            templateString: template,
            autoSizing: true,
            startup: function() {
                this.inherited(arguments);
                this._autoSize();
            }, // startup
            _autoSize: function() {
                if (! this.autoSizing) return;
                // setting to 'auto' first helps to shrink
                // the height when possible.
                this.textbox.style.height = "1em";
                this.textbox.scrollTop = 0;
                this.textbox.style.height =
                    this.textbox.scrollHeight + "px";
            }, // autoSize
            _onInput: function() {
                this.inherited(arguments);
                this._autoSize();
            }, // _onInput
            _onKey: function(e) {
                if (e.keyCode !== keys.SPACE
                    && e.keyCode !== keys.ENTER) {
                    this.inherited(arguments);
                }
                this._autoSize();
            }, // _onKey
            set: function() {
                this.inherited(arguments);
                this._autoSize();
            } // set
        });
    });
