define("lsmb/parts/PartDescription", [
    'dijit/form/Textarea',
    'dojo/_base/declare',
    'dojo/topic'
    ], function(
      Textarea,
        declare,
        topic
      ){
        return declare('lsmb/parts/PartsDescription',[Textarea], {
            linenum: null,
            height: null,
            startup: function() {
                var self = this;
                this.own(
                    topic.subscribe(
                        '/invoice/part-select/' + this.linenum,
                        function(selected) {
                            self.set('value',selected.description);
                        }));
            } // startup
        });
    });
